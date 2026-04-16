from fastapi import FastAPI, UploadFile, File
import librosa
import noisereduce as nr
import soundfile as sf
import os
import firebase_admin
from firebase_admin import credentials, storage

app = FastAPI()

# ١. إعداد الاتصال بالفايربيز
# تأكدي أن الملف بنفس المجلد
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': 'gs://faseh-98e8c.firebasestorage.app' # استبدلي PROJECT_ID باسم مشروعك في فايربيز
})

@app.post("/process-audio/")
async def process_audio(file: UploadFile = File(...)):
    # حفظ مؤقت للملف لمعالجته
    temp_raw = f"temp_{file.filename}"
    with open(temp_raw, "wb") as buffer:
        buffer.write(await file.read())

    # ٢. المعالجة (Denoising & Trimming)
    y, sr = librosa.load(temp_raw, sr=16000)
    y_denoised = nr.reduce_noise(y=y, sr=sr)
    y_trimmed, _ = librosa.effects.trim(y_denoised)
    
    # حفظ الملف المنظف مؤقتاً
    temp_clean = f"clean_{file.filename}"
    sf.write(temp_clean, y_trimmed, sr)

    # ٣. الرفع لـ Firebase Storage
    bucket = storage.bucket()
    blob = bucket.blob(f"processed_audios/{temp_clean}")
    blob.upload_from_filename(temp_clean)
    
    blob.make_public() # للحصول على رابط للملف (اختياري)

    # ٤. تنظيف السيرفر (حذف الملفات المؤقتة)
    os.remove(temp_raw)
    os.remove(temp_clean)

    return {"status": "success", "url": blob.public_url}