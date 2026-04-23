# Use a lightweight Python base image
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Install system dependencies required for audio processing
RUN apt-get update && apt-get install -y libsndfile1 ffmpeg && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Upgrade pip and install the SECURE, CPU-only version of PyTorch
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir "torch>=2.6.0" --index-url https://download.pytorch.org/whl/cpu

# Install the rest of the required Python libraries
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download the Hugging Face model
RUN python -c "from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor; Wav2Vec2Processor.from_pretrained('jonatasgrosman/wav2vec2-large-xlsr-53-arabic'); Wav2Vec2ForCTC.from_pretrained('jonatasgrosman/wav2vec2-large-xlsr-53-arabic')"

# Copy your Python code
COPY . .

# Set the default port to 8080
ENV PORT=8080

# The startup command
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]