from fastapi import FastAPI, UploadFile, File
import librosa
import noisereduce as nr
import soundfile as sf
import os
import firebase_admin
import numpy as np
from firebase_admin import credentials, storage

app = FastAPI()

# ١. إعداد الاتصال بالفايربيز
# تأكدي أن الملف بنفس المجلد ولا يحتوي على gs:// في الرابط
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred, {
        'storageBucket': 'faseh-98e8c.firebasestorage.app'
    })

@app.post("/process-audio/")
async def process_audio(file: UploadFile = File(...)):
    # مسارات فريدة للملفات لتجنب التداخل عند ضغط عدة مستخدمين
    temp_raw = f"/tmp/raw_{file.filename}"
    temp_clean = f"/tmp/clean_{file.filename}"

    try:
        # حفظ الملف الخام مؤقتاً
        with open(temp_raw, "wb") as buffer:
            buffer.write(await file.read())

        # ٢. المعالجة الاحترافية (Professional Preprocessing)
        # أ- التحميل وتوحيد التردد لـ 16kHz (المعيار العالمي لنماذج الكلام)
        y, sr = librosa.load(temp_raw, sr=16000)

        # ب- إزالة الضوضاء العنيفة (Aggressive Denoising)
        # stationary=True يحذف صوت المكيف والمراوح بدقة عالية
        # prop_decrease=1.0 يحذف 100% من الضوضاء المكتشفة
        y_denoised = nr.reduce_noise(
            y=y, 
            sr=sr, 
            stationary=True, 
            prop_decrease=1.0
        )

        # ج- قص الصمت الحاد (Sharp Trimming)
        # خفضنا الـ top_db لـ 10 لقص أي "نفس" أو وشوشة خفيفة قبل وبعد الكلام
        y_trimmed, _ = librosa.effects.trim(y_denoised, top_db=10)

        # د- توحيد مستوى الصوت (Normalization)
        # يضمن أن كل التسجيلات لها نفس "قوة" الصوت، مما يسهل عمل الـ AI لاحقاً
        if len(y_trimmed) > 0:
            y_final = librosa.util.normalize(y_trimmed)
        else:
            y_final = y_trimmed

        # حفظ الملف المنظف
        sf.write(temp_clean, y_final, sr)

        # ٣. الرفع لـ Firebase Storage
        bucket = storage.bucket()
        blob = bucket.blob(f"processed_audios/clean_{file.filename}")
        blob.upload_from_filename(temp_clean)
        
        blob.make_public()

        return {
            "status": "success", 
            "url": blob.public_url,
            "message": "Audio processed with high fidelity"
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}

    finally:
        # ٤. تنظيف السيرفر فوراً (Cleanup)
        if os.path.exists(temp_raw):
            os.remove(temp_raw)
        if os.path.exists(temp_clean):
            os.remove(temp_clean)