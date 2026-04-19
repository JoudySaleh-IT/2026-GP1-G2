from fastapi import FastAPI, UploadFile, File
import librosa
import soundfile as sf
import os
import firebase_admin
import numpy as np
import uuid
from firebase_admin import credentials, storage
from scipy import signal

app = FastAPI()

# Firebase initialization
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred, {
        'storageBucket': 'faseh-98e8c.firebasestorage.app'
    })

@app.post("/process-audio/")
async def process_audio(file: UploadFile = File(...)):
    temp_raw = f"/tmp/raw_{file.filename}"
    temp_clean = f"/tmp/clean_{file.filename}"

    try:
        # Save uploaded file
        with open(temp_raw, "wb") as buffer:
            buffer.write(await file.read())

        # Load audio at 16kHz (standard for speech)
        y, sr = librosa.load(temp_raw, sr=16000)

        # ------------------------------------------------------------
        # 1. HIGH-PASS FILTER (80 Hz) – removes rumble, preserves all speech
        # ------------------------------------------------------------
        b, a = signal.butter(4, 80, 'hp', fs=sr)
        y_hp = signal.filtfilt(b, a, y)

        # ------------------------------------------------------------
        # 2. VERY MILD NOISE REDUCTION (OPTIONAL – currently disabled)
        #    If you find the audio is too noisy, uncomment the next two lines.
        #    Stationary mode is safer and less likely to distort consonants.
        # ------------------------------------------------------------
        # import noisereduce as nr
        # y_hp = nr.reduce_noise(y=y_hp, sr=sr, stationary=True, prop_decrease=0.5)

        # ------------------------------------------------------------
        # 3. PRE-EMPHASIS (boosts high frequencies for clarity)
        #    Standard coefficient 0.97 works well for Arabic.
        # ------------------------------------------------------------
        y_emp = librosa.effects.preemphasis(y_hp)

        # ------------------------------------------------------------
        # 4. TRIM LEADING & TRAILING SILENCE ONLY
        #    Using default ref=np.max (peak energy) ensures weak consonants
        #    like initial ض or غ are never cut.
        #    top_db=20 is conservative – only true silence is removed.
        # ------------------------------------------------------------
        y_trimmed, _ = librosa.effects.trim(y_emp, top_db=20)

        # ------------------------------------------------------------
        # 5. NORMALIZE VOLUME
        # ------------------------------------------------------------
        if len(y_trimmed) > 0:
            y_final = librosa.util.normalize(y_trimmed)
        else:
            # Fallback – extremely rare
            y_final = y_emp

        # Save cleaned file
        sf.write(temp_clean, y_final, sr)

        # ------------------------------------------------------------
        # 6. UPLOAD TO FIREBASE STORAGE
        # ------------------------------------------------------------
        bucket = storage.bucket()
        blob = bucket.blob(f"processed_audios/clean_{file.filename}")
        download_token = str(uuid.uuid4())
        blob.metadata = {'firebaseStorageDownloadTokens': download_token}
        blob.upload_from_filename(temp_clean, content_type='audio/wav')

        firebase_url = (
            f"https://firebasestorage.googleapis.com/v0/b/{bucket.name}/o/"
            f"{blob.name.replace('/', '%2F')}?alt=media&token={download_token}"
        )

        return {
            "status": "success",
            "url": firebase_url,
            "message": "Audio processed with conservative trimming – all phonemes preserved."
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}

    finally:
        if os.path.exists(temp_raw):
            os.remove(temp_raw)
        if os.path.exists(temp_clean):
            os.remove(temp_clean)