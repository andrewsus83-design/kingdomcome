"""
Kingdom Come — Bark TTS on Modal.com
Deploy: modal deploy tts_app.py
URL:    https://{your-username}--kingdom-come-tts-narrate.modal.run
"""

import modal

app = modal.App("kingdom-come-tts")

image = (
    modal.Image.from_registry(
        "pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime",
        add_python="3.11",
    )
    .env({"DEBIAN_FRONTEND": "noninteractive"})
    .run_commands(
        "pip install --upgrade pip",
        "pip install bark scipy numpy",
    )
)


@app.function(
    image=image,
    gpu="T4",
    timeout=120,
    container_idle_timeout=300,
)
@modal.web_endpoint(method="POST")
def narrate(item: dict) -> dict:
    from bark import SAMPLE_RATE, generate_audio, preload_models
    import scipy.io.wavfile as wav
    import base64
    import io

    preload_models()

    text = item.get("text", "")
    voice_preset = item.get("voice_preset", "v2/en_speaker_6")

    if not text:
        return {"error": "Field 'text' is required."}

    audio_array = generate_audio(text, history_prompt=voice_preset)

    buffer = io.BytesIO()
    wav.write(buffer, SAMPLE_RATE, audio_array)
    audio_b64 = base64.b64encode(buffer.getvalue()).decode()

    return {
        "audio_base64": audio_b64,
        "sample_rate": SAMPLE_RATE,
        "format": "wav",
    }
