from fastapi import FastAPI, UploadFile, File, Form
import librosa
import soundfile as sf
import os
import firebase_admin
import numpy as np
import uuid
import re
from firebase_admin import credentials, storage
from scipy import signal
from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor
import torch


def levenshtein_distance(a, b):
    if len(a) < len(b):
        return levenshtein_distance(b, a)

    previous_row = range(len(b) + 1)

    for i, char_a in enumerate(a):
        current_row = [i + 1]

        for j, char_b in enumerate(b):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (char_a != char_b)

            current_row.append(
                min(insertions, deletions, substitutions)
            )

        previous_row = current_row

    return previous_row[-1]


def normalize_arabic_text(text):
    # Remove Arabic diacritics and Tatweel
    text = re.sub(r'[\u064B-\u065F\u0670\u0640]', '', text)

    # Normalize common Alef forms
    text = text.replace('أ', 'ا')
    text = text.replace('إ', 'ا')
    text = text.replace('آ', 'ا')

    # Remove extra spaces
    text = ' '.join(text.split())

    return text.strip()


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
    temp_clean = f"/tmp/clean_{os.path.splitext(file.filename)[0]}.wav"

    try:
        # حفظ الملف الصوتي المرفوع
        with open(temp_raw, "wb") as buffer:
            buffer.write(await file.read())

        # =================================================
        # 1. Digital Signal Processing (Preprocessing)
        # =================================================

        y, sr = librosa.load(
            temp_raw,
            sr=16000
        )

        # -------------------------------------------------
        # Validation Rule 1:
        # Recording is too short
        # -------------------------------------------------

        duration = librosa.get_duration(
            y=y,
            sr=sr
        )

        if duration < 0.2:
            return {
                "status": "invalid_audio",
                "reason": "too_short",
                "message": "Recording is too short."
            }

        # High-pass filter
        b, a = signal.butter(
            4,
            80,
            'hp',
            fs=sr
        )

        y_hp = signal.filtfilt(
            b,
            a,
            y
        )

        # Silence removal
        y_trimmed, _ = librosa.effects.trim(
            y_hp,
            top_db=35
        )

        # -------------------------------------------------
        # Validation Rule 2:
        # No speech detected
        # -------------------------------------------------

        if len(y_trimmed) == 0:
            return {
                "status": "invalid_audio",
                "reason": "no_speech",
                "message": "No speech detected."
            }

        # If trimming leaves less than 0.2 seconds,
        # use the original filtered recording instead
        # of rejecting the child's recording.
        if len(y_trimmed) < (sr * 0.2):
            y_final = librosa.util.normalize(
                y_hp
            )

        else:
            y_final = librosa.util.normalize(
                y_trimmed
            )

        sf.write(
            temp_clean,
            y_final,
            sr
        )

        # =================================================
        # 2. AI Transcription
        # =================================================

        inputs = processor(
            y_final,
            sampling_rate=16000,
            return_tensors="pt",
            padding=True
        )

        with torch.no_grad():
            logits = model(
                inputs.input_values
            ).logits

        predicted_ids = torch.argmax(
            logits,
            dim=-1
        )

        transcription = processor.batch_decode(
            predicted_ids
        )[0].strip()

        # -------------------------------------------------
        # Validation Rule 3:
        # Empty transcription
        # -------------------------------------------------

        if not transcription:
            return {
                "status": "invalid_audio",
                "reason": "empty_transcript",
                "message": "No transcription was generated."
            }

        # Normalize target and transcription
        # only for validation checks.
        normalized_target = normalize_arabic_text(
            target_word
        )

        normalized_transcription = normalize_arabic_text(
            transcription
        )

        transcription_words = (
            normalized_transcription.split()
        )

        # -------------------------------------------------
        # Validation Rule 4:
        # Child repeated the target word
        # Example: "قمر قمر"
        # -------------------------------------------------

        if (
            len(transcription_words) > 1
            and all(
                word == normalized_target
                for word in transcription_words
            )
        ):
            return {
                "status": "invalid_audio",
                "reason": "repeated_word",
                "message": "The target word was repeated."
            }

        # -------------------------------------------------
        # Validation Rule 5:
        # Completely different word
        # -------------------------------------------------

        if len(transcription_words) == 1:

            validation_distance = levenshtein_distance(
                normalized_target,
                normalized_transcription
            )

            validation_max_length = max(
                len(normalized_target),
                len(normalized_transcription)
            )

            if validation_max_length > 0:

                word_similarity = (
                    1 -
                    (
                        validation_distance /
                        validation_max_length
                    )
                )

                # Very low similarity means that the child
                # most likely said a completely different word.
                if word_similarity <= 0.25:
                    return {
                        "status": "invalid_audio",
                        "reason": "different_word",
                        "message": "A different word was detected."
                    }

        # =================================================
        # 3. Targeted Scoring Algorithm
        # =================================================

        final_score = 0.0

        if target_letter in transcription:

            # Calculating accuracy based on phonetic distance
            mistakes = levenshtein_distance(
                target_word,
                transcription
            )

            total_letters = len(
                target_word
            )

            # Accuracy is calculated as the true percentage
            # of correct phonemes
            accuracy = max(
                0,
                100 - (
                    (mistakes / total_letters) * 100
                )
            )

            # Final Score reflects the real accuracy,
            # no matter how low it is
            final_score = accuracy

        else:
            # Target letter is missing or mispronounced.
            #
            # This is NOT an invalid recording.
            # The child's recording is valid and their
            # pronunciation performance is measured as-is.
            #
            # Therefore, no invalid retry is triggered.
            final_score = 0.0

        # =================================================
        # 4. الرفع إلى Firebase Storage
        # =================================================

        bucket = storage.bucket()

        blob = bucket.blob(
    f"processed_audios/clean_{os.path.splitext(file.filename)[0]}.wav"
)

        download_token = str(
            uuid.uuid4()
        )

        blob.metadata = {
            'firebaseStorageDownloadTokens':
                download_token
        }

        blob.upload_from_filename(
            temp_clean,
            content_type='audio/wav'
        )

        firebase_url = (
            f"https://firebasestorage.googleapis.com/v0/b/"
            f"{bucket.name}/o/"
            f"{blob.name.replace('/', '%2F')}"
            f"?alt=media&token={download_token}"
        )

        return {
            "status": "success",
            "url": firebase_url,
            "score": round(final_score),
            "transcription_heard": transcription,
            "target_word": target_word,
            "target_letter": target_letter
        }

    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }

    finally:
        # تنظيف الملفات المؤقتة
        if os.path.exists(temp_raw):
            os.remove(temp_raw)

        if os.path.exists(temp_clean):
            os.remove(temp_clean)