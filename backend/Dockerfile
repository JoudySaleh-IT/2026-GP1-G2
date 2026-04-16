# استخدام نسخة بايثون مستقرة
FROM python:3.9-slim

# تثبيت مكتبات النظام اللازمة لمعالجة الصوت (libsndfile و ffmpeg)
RUN apt-get update && apt-get install -y libsndfile1 ffmpeg && rm -rf /var/lib/apt/lists/*

# تحديد مجلد العمل داخل الحاوية
WORKDIR /app

# نسخ ملف المتطلبات وتثبيتها
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# نسخ بقية الكود (بما في ذلك ملف serviceAccountKey.json)
COPY . .

# تشغيل السيرفر (جوجل يحدد البورت تلقائياً عبر المتغير $PORT)
CMD exec uvicorn main:app --host 0.0.0.0 --port $PORT