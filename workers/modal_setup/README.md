# Kingdom Come — Modal.com Audio Setup

This directory documents how to deploy the open-source audio models used by Kingdom Come on [Modal.com](https://modal.com). All audio generation (TTS narration and music) runs on Modal using GPU-backed serverless functions, with a single `MODAL_API_KEY`.

---

## Prerequisites

```bash
pip install modal
modal token new   # authenticate your Modal account
```

---

## 1. Deploy Bark TTS (Narration)

Save the following as `tts_app.py` and deploy it.

```python
import modal

app = modal.App("kingdom-come-tts")
image = modal.Image.debian_slim().pip_install("bark", "scipy", "numpy")

@app.function(image=image, gpu="T4", secrets=[modal.Secret.from_name("kingdom-come")])
@modal.web_endpoint(method="POST")
def narrate(item: dict):
    from bark import SAMPLE_RATE, generate_audio, preload_models
    import scipy.io.wavfile as wav
    import base64, io
    preload_models()
    text = item.get("text", "")
    voice_preset = item.get("voice_preset", "v2/en_speaker_6")
    audio_array = generate_audio(text, history_prompt=voice_preset)
    buffer = io.BytesIO()
    wav.write(buffer, SAMPLE_RATE, audio_array)
    audio_b64 = base64.b64encode(buffer.getvalue()).decode()
    return {"audio_base64": audio_b64, "sample_rate": SAMPLE_RATE}
```

Deploy:

```bash
modal deploy tts_app.py
```

After deploying, Modal will print a URL like:

```
https://{your-modal-username}--kingdom-come-tts.modal.run/narrate
```

Copy this value into `MODAL_TTS_URL`.

### TTS request format

```json
{
  "text": "In the beginning, God created the heavens and the earth.",
  "voice_preset": "v2/en_speaker_6"
}
```

### TTS response format

```json
{
  "audio_base64": "<base64-encoded WAV>",
  "sample_rate": 22050
}
```

---

## 2. Deploy MusicGen (Music Generation)

Save the following as `music_app.py` and deploy it.

```python
import modal

app = modal.App("kingdom-come-music")
image = modal.Image.debian_slim().pip_install("transformers", "scipy", "torch", "audiocraft")

@app.function(image=image, gpu="T4", timeout=120)
@modal.web_endpoint(method="POST")
def generate(item: dict):
    from audiocraft.models import MusicGen
    from audiocraft.data.audio import audio_write
    import base64, io, torch
    model = MusicGen.get_pretrained("facebook/musicgen-small")
    model.set_generation_params(duration=item.get("duration", 30))
    descriptions = [item.get("prompt", "Catholic gregorian chant peaceful ambient")]
    wav = model.generate(descriptions)
    buffer = io.BytesIO()
    audio_write(buffer, wav[0].cpu(), model.sample_rate, format="mp3")
    return {"audio_base64": base64.b64encode(buffer.getvalue()).decode()}
```

Deploy:

```bash
modal deploy music_app.py
```

After deploying, Modal will print a URL like:

```
https://{your-modal-username}--kingdom-come-music.modal.run/generate
```

Copy this value into `MODAL_MUSIC_URL`.

### Music request format

```json
{
  "prompt": "Peaceful Advent Catholic chant, contemplative Gregorian plainchant with strings",
  "duration": 30
}
```

### Music response format

```json
{
  "audio_base64": "<base64-encoded MP3>"
}
```

---

## 3. Set Cloudflare Worker secrets

After deploying both Modal apps, add the endpoint URLs as Cloudflare Worker secrets so they are available to the AI Gateway worker at runtime:

```bash
# From the workers/ai-gateway directory:
wrangler secret put MODAL_API_KEY
wrangler secret put MODAL_TTS_URL
wrangler secret put MODAL_MUSIC_URL
```

When prompted, paste the corresponding values:

| Secret           | Value                                                                          |
|------------------|--------------------------------------------------------------------------------|
| `MODAL_API_KEY`  | Your Modal API token (from `modal token new` or the Modal dashboard)           |
| `MODAL_TTS_URL`  | `https://{your-username}--kingdom-come-tts.modal.run/narrate`                  |
| `MODAL_MUSIC_URL`| `https://{your-username}--kingdom-come-music.modal.run/generate`               |

> **Note:** Secrets set via `wrangler secret put` override the empty placeholder values in `wrangler.toml`. Never commit real values to `wrangler.toml` or `.env`.

---

## 4. Voice preset reference (Bark)

Bark supports a range of built-in voice presets. Some useful ones for narration:

| Preset              | Description                  |
|---------------------|------------------------------|
| `v2/en_speaker_6`   | Clear male narrator (default)|
| `v2/en_speaker_9`   | Warm female voice            |
| `v2/en_speaker_0`   | Young male voice             |

Pass the preset in the request body as `voice_preset`.
