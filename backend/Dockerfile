# 1. استخدام نسخة بايثون خفيفة
FROM python:3.10-slim

# 2. تحديد مجلد العمل
WORKDIR /app

# 3. تثبيت مكتبات النظام الضرورية لمعالجة الصوت
RUN apt-get update && apt-get install -y libsndfile1 ffmpeg && rm -rf /var/lib/apt/lists/*

# 4. نسخ ملف المكتبات أولاً (لتحسين سرعة البناء مستقبلاً)
COPY requirements.txt .

# 5. تحديث pip وتثبيت نسخة PyTorch المخصصة للمعالجات (بدون GPU لأن السيرفر CPU)
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu

# 6. تثبيت باقي المكتبات المطلوبة
RUN pip install --no-cache-dir -r requirements.txt

# 7. نسخ كل ملفات المشروع (بما في ذلك مجلد final_faseeh_model)
COPY . .

# --- ملاحظة هامة ---
# قمنا بحذف سطر RUN python -c "from transformers..." 
# لأن الموديل الآن موجود محلياً في مجلدك ولن نحمله من الإنترنت.

# 8. تحديد المنفذ الافتراضي
ENV PORT=8080

# 9. أمر التشغيل
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]