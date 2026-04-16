from fastapi import FastAPI, UploadFile, File, HTTPException
import librosa
import noisereduce as nr
import soundfile as sf
import os
import shutil
from pathlib import Path

app = FastAPI(title="Faseeh AI Preprocessing Engine")

# --- المسارات على الهارد ديسك الخارجي DevSSD ---
BASE_DIR = Path("/Volumes/DevSSD/Faseeh_AI_Platform")
RAW_DIR = BASE_DIR / "data" / "raw_uploads"
CLEAN_DIR = BASE_DIR / "data" / "processed_audios"

# إنشاء المجلدات تلقائياً إذا كانت غير موجودة
RAW_DIR.mkdir(parents=True, exist_ok=True)
CLEAN_DIR.mkdir(parents=True, exist_ok=True)

@app.get("/")
def home():
    return {"message": "سيرفر فصيح يعمل بنجاح من الهارد ديسك الخارجي!"}

@app.post("/process-audio/")
async def process_audio(file: UploadFile = File(...)):
    try:
        # ١. حفظ الملف الخام الأصلي (Raw)
        raw_path = RAW_DIR / file.filename
        with raw_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # ٢. التحميل والمعالجة (Resampling to 16kHz)
        y, sr = librosa.load(str(raw_path), sr=16000)

        # ٣. Noise Reduction: إزالة وشوشة المايكروفون المحيطة بالطفل
        y_denoised = nr.reduce_noise(y=y, sr=sr)

        # ٤. Silence Trimming: حذف الفراغات قبل وبعد الكلام
        y_trimmed, _ = librosa.effects.trim(y_denoised, top_db=20)

        # ٥. Normalization: توحيد مستوى الصوت لثبات جودة البيانات
        y_normalized = librosa.util.normalize(y_trimmed)

        # ٦. حفظ النسخة المنظفة في مجلد processed_audios
        output_filename = f"clean_{file.filename}"
        output_path = CLEAN_DIR / output_filename
        sf.write(str(output_path), y_normalized, sr)

        return {
            "status": "success",
            "metadata": {
                "original_name": file.filename,
                "clean_path": str(output_path),
                "duration": float(librosa.get_duration(y=y_normalized, sr=sr)),
                "sample_rate": sr
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))