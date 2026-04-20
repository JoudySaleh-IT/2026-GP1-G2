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
    target_word: str = Form(...) 
):
    temp_raw = f"/tmp/raw_{file.filename}"
    temp_clean = f"/tmp/clean_{file.filename}"

    try:
        # Save raw audio
        with open(temp_raw, "wb") as buffer:
            buffer.write(await file.read())

        # 3. Audio Preprocessing (Optimized for children)
        y, sr = librosa.load(temp_raw, sr=16000)
        b, a = signal.butter(4, 80, 'hp', fs=sr)
        y_hp = signal.filtfilt(b, a, y)
        y_emp = librosa.effects.preemphasis(y_hp)
        y_trimmed, _ = librosa.effects.trim(y_emp, top_db=20)

        if len(y_trimmed) > 0:
            y_final = librosa.util.normalize(y_trimmed)
        else:
            y_final = y_emp

        sf.write(temp_clean, y_final, sr)

        # 4. AI Evaluation
        inputs = processor(y_final, sampling_rate=16000, return_tensors="pt", padding=True)
        with torch.no_grad():
            logits = model(inputs.input_values).logits
        
        predicted_ids = torch.argmax(logits, dim=-1)
        transcription = processor.batch_decode(predicted_ids)[0]
        
        # Calculate Character Error Rate (CER)
        mistakes = editdistance.eval(target_word, transcription)
        total_letters = len(target_word)
        accuracy = max(0, 100 - ((mistakes / total_letters) * 100))

        # 5. Upload to Firebase
        bucket = storage.bucket()
        blob = bucket.blob(f"processed_audios/clean_{file.filename}")
        
        download_token = str(uuid.uuid4())
        blob.metadata = {'firebaseStorageDownloadTokens': download_token}
        blob.upload_from_filename(temp_clean, content_type='audio/wav')

        firebase_url = (
            f"https://firebasestorage.googleapis.com/v0/b/{bucket.name}/o/"
            f"{blob.name.replace('/', '%2F')}?alt=media&token={download_token}"
        )

        # 6. Return Data to Flutter (THIS IS WHAT WAS MISSING!)
        return {
            "status": "success",
            "url": firebase_url,
            "score": round(accuracy),
            "transcription_heard": transcription,
            "target": target_word
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}

    finally:
        # Clean up temporary files
        if os.path.exists(temp_raw):
            os.remove(temp_raw)
        if os.path.exists(temp_clean):
            os.remove(temp_clean)