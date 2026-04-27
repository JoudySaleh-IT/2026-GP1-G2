from fastapi import FastAPI, UploadFile, File, Form
import librosa
import soundfile as sf
import os
import firebase_admin
import numpy as np
import uuid
from firebase_admin import credentials, storage
from scipy import signal
from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor
import torch
import editdistance

app = FastAPI()

# 1. إعداد Firebase
if not firebase_admin._apps:
    firebase_admin.initialize_app(options={
        'storageBucket': 'faseh-98e8c.firebasestorage.app'
    })

# 2. تحميل موديل "فصيح" المخصص (Fine-tuned Model)
MODEL_PATH = "./final_faseeh_model"

print("Loading Custom Faseeh AI Model for Kids...")
processor = Wav2Vec2Processor.from_pretrained(MODEL_PATH)
model = Wav2Vec2ForCTC.from_pretrained(MODEL_PATH)
print("Success: Custom Model loaded from local directory!")

@app.post("/process-audio/")
async def process_audio(
    file: UploadFile = File(...), 
    target_word: str = Form(...),
    target_letter: str = Form(...) 
):
    temp_raw = f"/tmp/raw_{file.filename}"
    temp_clean = f"/tmp/clean_{file.filename}"

    try:
        # حفظ الملف الصوتي المرفوع
        with open(temp_raw, "wb") as buffer:
            buffer.write(await file.read())

        # 1. المعالجة الصوتية (Audio Preprocessing)
        y, sr = librosa.load(temp_raw, sr=16000)
        
        # مرشح تمرير عالي لإزالة الضجيج في الترددات المنخفضة
        b, a = signal.butter(4, 80, 'hp', fs=sr)
        y_hp = signal.filtfilt(b, a, y)
        
        # قص الصمت (متساهل مع الأطفال)
        y_trimmed, _ = librosa.effects.trim(y_hp, top_db=35) 
        
        if len(y_trimmed) < (sr * 0.2): 
            y_final = librosa.util.normalize(y_hp)
        else:
            y_final = librosa.util.normalize(y_trimmed)

        sf.write(temp_clean, y_final, sr)

        # 2. استخراج النص باستخدام الموديل المخصص
        inputs = processor(y_final, sampling_rate=16000, return_tensors="pt", padding=True)
        with torch.no_grad():
            logits = model(inputs.input_values).logits
        
        predicted_ids = torch.argmax(logits, dim=-1)
        transcription = processor.batch_decode(predicted_ids)[0].strip()

        # 3. خوارزمية التقييم المعدلة (بدون ضرب 1.2)
        final_score = 0.0

        if not transcription:
            final_score = 0.0 
            
        elif target_letter in transcription:
            # تم حذف معامل الضرب 1.2 لأن الموديل أصبح أدق في الفهم
            mistakes = editdistance.eval(target_word, transcription)
            total_letters = len(target_word)
            # حساب الدقة بناءً على المسافة اللغوية الحقيقية
            final_score = max(0, 100 - ((mistakes / total_letters) * 100))
            
            # إذا نطق الحرف المستهدف، نعطيه دفعة معنوية بسيطة للحد الأدنى فقط
            if final_score < 70:
                final_score = 75.0
            
        else:
            # في حال عدم وجود الحرف المستهدف، الدرجة تعتمد على دقة الكلمة بحد أقصى 60
            mistakes = editdistance.eval(target_word, transcription)
            total_letters = len(target_word)
            word_accuracy = max(0, 100 - ((mistakes / total_letters) * 100))
            final_score = min(60.0, word_accuracy)

        # ضمان أن الدرجة بين 0 و 100
        final_score = max(0.0, min(100.0, final_score))
        
        # 4. الرفع إلى Firebase Storage
        bucket = storage.bucket()
        blob = bucket.blob(f"processed_audios/clean_{file.filename}")
        download_token = str(uuid.uuid4())
        blob.metadata = {'firebaseStorageDownloadTokens': download_token}
        blob.upload_from_filename(temp_clean, content_type='audio/wav')
        firebase_url = f"https://firebasestorage.googleapis.com/v0/b/{bucket.name}/o/{blob.name.replace('/', '%2F')}?alt=media&token={download_token}"

        return {
            "status": "success",
            "url": firebase_url,
            "score": round(final_score),
            "transcription_heard": transcription,
            "target_word": target_word,
            "target_letter": target_letter
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}

    finally:
        # تنظيف الملفات المؤقتة
        if os.path.exists(temp_raw): os.remove(temp_raw)
        if os.path.exists(temp_clean): os.remove(temp_clean)