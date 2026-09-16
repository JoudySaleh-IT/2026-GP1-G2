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
import webrtcvad


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
def contains_speech(
    audio,
    sample_rate=16000,
    mode=0,
    frame_duration_ms=10,
    min_speech_frames=2
):
    """
    Detect whether the recording contains human speech.

    This configuration is intentionally permissive because
    Faseh contains very short Arabic words such as "خس" and "مخ".
    """

    vad = webrtcvad.Vad(mode)

    # Convert librosa float audio (-1.0 to 1.0)
    # into 16-bit PCM required by WebRTC VAD.
    audio = np.clip(audio, -1.0, 1.0)

    pcm_audio = (
        audio * 32767
    ).astype(np.int16)

    frame_size = int(
        sample_rate * frame_duration_ms / 1000
    )

    speech_frames = 0

    for start in range(
        0,
        len(pcm_audio) - frame_size + 1,
        frame_size
    ):
        frame = pcm_audio[
            start:start + frame_size
        ]

        frame_bytes = frame.tobytes()

        if vad.is_speech(
            frame_bytes,
            sample_rate
        ):
            speech_frames += 1

            # Only 2 × 10 ms = 20 ms of detected speech
            # is enough to accept the recording.
            if speech_frames >= min_speech_frames:
                return True

    return False

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
        # Voice Activity Detection
        # -------------------------------------------------

        if not contains_speech(
            y,
            sample_rate=sr
        ):
            return {
                "status": "invalid_audio",
                "reason": "no_speech",
                "message": "No speech detected."
            }

        # Use the same audio preparation used during fine-tuning.
        y_final = y

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
        # for validation and scoring.
        normalized_target = normalize_arabic_text(
            target_word
        )

        normalized_transcription = normalize_arabic_text(
            transcription
        )

        # Ignore the Arabic definite article "ال"
        # when the ASR adds it to the target word.
        if normalized_transcription == "ال" + normalized_target:
            normalized_transcription = normalized_target

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

# Different-word validation temporarily disabled
# to avoid rejecting valid pronunciations due to ASR errors.

        # =================================================
        # 3. Targeted Scoring Algorithm
        # =================================================
        final_score = 0.0

        normalized_letter = normalize_arabic_text(
            target_letter
        )

        if normalized_letter in normalized_transcription:

            mistakes = levenshtein_distance(
                normalized_target,
                normalized_transcription
            )

            total_letters = len(
                normalized_target
            )

            accuracy = max(
                0,
                100 - (
                    (mistakes / total_letters) * 100
                )
            )

            final_score = accuracy

        else:
            final_score = 0.0

        # =================================================
        # DEBUG — Check ASR vs Rule-Based Scoring
        # =================================================

        debug_distance = levenshtein_distance(
            normalized_target,
            normalized_transcription
        )

        debug_max_length = max(
            len(normalized_target),
            len(normalized_transcription)
        )

        debug_similarity = (
            1 - (debug_distance / debug_max_length)
            if debug_max_length > 0
            else 0.0
        )

        print("\n========== FASEH DEBUG ==========")
        print("Expected word (raw):", repr(target_word))
        print("Target letter:", repr(target_letter))
        print("ASR transcription (raw):", repr(transcription))
        print("Normalized expected:", repr(normalized_target))
        print("Normalized transcription:", repr(normalized_transcription))
        print(
            "Target detected in RAW transcription:",
            target_letter in transcription
        )
        print(
            "Target detected after normalization:",
            normalize_arabic_text(target_letter)
            in normalized_transcription
        )
        print("Edit distance:", debug_distance)
        print("Similarity:", round(debug_similarity, 4))
        print("Similarity (%):", round(debug_similarity * 100, 2))
        print("Final score:", final_score)
        print("=================================\n")

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