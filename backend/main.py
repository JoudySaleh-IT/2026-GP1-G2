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

# 1. Digital Signal Processing (Preprocessing)
        y, sr = librosa.load(temp_raw, sr=16000)
        
        # Validation Rule 1: Check minimum duration threshold
        duration = librosa.get_duration(y=y, sr=sr)
        if duration < 0.2:
            return {"status": "invalid_audio", "message": "Recording is too short."}
        
        b, a = signal.butter(4, 80, 'hp', fs=sr)
        y_hp = signal.filtfilt(b, a, y)
        
        y_trimmed, _ = librosa.effects.trim(y_hp, top_db=35) # Silence removal
        
        # Validation Rule 2: Check for empty recording after trimming
        if len(y_trimmed) == 0:
            return {"status": "invalid_audio", "message": "No speech detected."}
            
        if len(y_trimmed) < (sr * 0.2): 
            y_final = librosa.util.normalize(y_hp)
        else:
            y_final = librosa.util.normalize(y_trimmed)

        sf.write(temp_clean, y_final, sr)

        # 2. AI Transcription
        inputs = processor(y_final, sampling_rate=16000, return_tensors="pt", padding=True)
        with torch.no_grad():
            logits = model(inputs.input_values).logits
        
        predicted_ids = torch.argmax(logits, dim=-1)
        transcription = processor.batch_decode(predicted_ids)[0].strip()

        final_score = 0.0
        # 3. Targeted Scoring Algorithm
        if not transcription:
           
            final_score = 0.0 # Strict failure if target letter is missed
            
        elif target_letter in transcription:
            # Calculating accuracy based on phonetic distance
            mistakes = editdistance.eval(target_word, transcription)
            total_letters = len(target_word)
            
            # Accuracy is calculated as the true percentage of correct phonemes
            accuracy = max(0, 100 - ((mistakes / total_letters) * 100))
            
            # Final Score reflects the real accuracy, no matter how low it is
            final_score = accuracy
            
        else:
            # 3. Fallback: Target letter missing
            # The score is strictly zero because the primary educational goal was not met
            final_score = 0.0
            
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