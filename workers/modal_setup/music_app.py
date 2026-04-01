"""
Kingdom Come — MusicGen on Modal.com
Deploy: modal deploy music_app.py
URL:    https://{your-username}--kingdom-come-music-generate.modal.run
"""

import modal

app = modal.App("kingdom-come-music")

# Use PyTorch CUDA base image — avoids torch version conflicts with audiocraft
image = (
    modal.Image.from_registry(
        "pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime",
        add_python="3.11",
    )
    .run_commands(
        "pip install --upgrade pip",
        "pip install audiocraft",
        "pip install scipy",
    )
)


@app.function(
    image=image,
    gpu="T4",
    timeout=300,
    container_idle_timeout=300,
)
@modal.web_endpoint(method="POST")
def generate(item: dict) -> dict:
    from audiocraft.models import MusicGen
    import base64
    import io
    import torchaudio

    prompt = item.get("prompt", "Peaceful Catholic Gregorian chant ambient")
    duration = int(item.get("duration", 30))
    duration = max(5, min(duration, 60))  # clamp 5–60 seconds

    model = MusicGen.get_pretrained("facebook/musicgen-small")
    model.set_generation_params(duration=duration)

    wav = model.generate([prompt])  # shape: [1, channels, samples]

    buffer = io.BytesIO()
    torchaudio.save(buffer, wav[0].cpu(), model.sample_rate, format="mp3")
    buffer.seek(0)

    return {
        "audio_base64": base64.b64encode(buffer.read()).decode(),
        "sample_rate": model.sample_rate,
        "format": "mp3",
        "duration_seconds": duration,
    }
