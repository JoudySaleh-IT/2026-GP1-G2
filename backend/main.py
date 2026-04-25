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

# 1. Firebase Setup (Cloud Native Version!)
if not firebase_admin._apps:
    # Notice we removed the "cred" line completely. 
    # Cloud Run will automatically use its built-in security badge!
    firebase_admin.initialize_app(options={
        'storageBucket': 'faseh-98e8c.firebasestorage.app'
    })

# 2. Load the AI Model (Loads into memory when Cloud Run starts)
print("Loading Arabic AI Model...")
processor = Wav2Vec2Processor.from_pretrained("jonatasgrosman/wav2vec2-large-xlsr-53-arabic")
model = Wav2Vec2ForCTC.from_pretrained("jonatasgrosman/wav2vec2-large-xlsr-53-arabic")
print("Model loaded successfully!")

@app.post("/process-audio/")
async def process_audio(
    file: UploadFile = File(...), 
    target_word: str = Form(...),
    target_letter: str = Form(...) 
):
    temp_raw = f"/tmp/raw_{file.filename}"
    temp_clean = f"/tmp/clean_{file.filename}"

    try:
        # حفظ الملف الصوتي
        with open(temp_raw, "wb") as buffer:
            buffer.write(await file.read())

        # 1. معالجة صوتية (رحيمة بالأطفال)
        y, sr = librosa.load(temp_raw, sr=16000)
        b, a = signal.butter(4, 80, 'hp', fs=sr)
        y_hp = signal.filtfilt(b, a, y)
        
        #  تم التعديل هنا: جعلنا قص الصمت متساهلاً جداً (top_db=35 بدل 20) لكي لا نحذف الكلمات الهادئة
        y_trimmed, _ = librosa.effects.trim(y_hp, top_db=35) 
        
        # إذا تم قص الكلمة بالكامل بالخطأ، نعود للصوت الأصلي
        if len(y_trimmed) < (sr * 0.2): 
            y_final = librosa.util.normalize(y_hp)
        else:
            y_final = librosa.util.normalize(y_trimmed)

        sf.write(temp_clean, y_final, sr)

        # 2. استخراج النص من الذكاء الاصطناعي
        inputs = processor(y_final, sampling_rate=16000, return_tensors="pt", padding=True)
        with torch.no_grad():
            logits = model(inputs.input_values).logits
        
        predicted_ids = torch.argmax(logits, dim=-1)
        transcription = processor.batch_decode(predicted_ids)[0].strip()
        
<<<<<<< HEAD
        # 3.  خوارزمية التقييم المخصصة للحرف المستهدف 
        final_score = 15.0 # الدرجة الافتراضية لمحاولة الطفل (حتى لا يأخذ صفر أبداً)
=======
        # 3. خوارزمية التقييم المخصصة للحرف المستهدف 🌟
        final_score = 0.0 # تبدأ الدرجة من صفر
>>>>>>> b74ffbe7ce06cc428ad6754ec2eb761c58c4a299

        if not transcription:
            # إذا لم يسمع المودل أي شيء (صمت تام أو صوت غير مفهوم)
            final_score = 0.0 
            
        elif target_letter in transcription:
            # الحالة الذهبية: الطفل نطق الحرف المستهدف بنجاح والمودل سمعه!
            mistakes = editdistance.eval(target_word, transcription)
            total_letters = len(target_word)
            word_accuracy = max(0, 100 - ((mistakes / total_letters) * 100))
            
            # نعطيه أعلى درجة: إما 85 كحد أدنى مكافأة له، أو دقة الكلمة إذا كانت أعلى
            final_score = max(85.0, word_accuracy * 1.2) 
            
        else:
            # الحالة السلبية: الحرف المستهدف غير موجود في الكلمة
            mistakes = editdistance.eval(target_word, transcription)
            total_letters = len(target_word)
            word_accuracy = max(0, 100 - ((mistakes / total_letters) * 100))
            
            # بما أنه أخطأ في الحرف المستهدف، الدرجة لن تتجاوز 65% 
            # وإذا كانت دقة الكلمة سيئة جداً، ستنزل الدرجة بشكل طبيعي وقد تصل إلى الصفر
            final_score = min(65.0, word_accuracy * 1.2)

        # قانون منع القيم الشاذة (الحد الأدنى 0 والحد الأقصى 100)
        final_score = max(0.0, min(100.0, final_score))
        
        # الرفع للفايربيس
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
        if os.path.exists(temp_raw): os.remove(temp_raw)
        if os.path.exists(temp_clean): os.remove(temp_clean)