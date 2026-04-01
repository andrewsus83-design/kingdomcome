"""
Kingdom Come — FLUX.1-dev Image Generation on Modal.com
Deploy:  modal deploy flux_app.py
URL:     https://{username}--kingdom-come-flux-generate.modal.run

POST body:
{
  "prompt": "Pixar 3D style young boy saint...",
  "width": 1024,
  "height": 1024,
  "steps": 28,
  "guidance_scale": 3.5,
  "seed": 42          # optional, omit for random
}

Returns:
{
  "image_base64": "...",
  "format": "png",
  "width": 1024,
  "height": 1024,
  "seed": 12345
}
"""

import modal

app = modal.App("kingdom-come-flux")

# Persistent volume to cache model weights (~24GB) — avoids re-downloading on cold start
model_volume = modal.Volume.from_name("kingdom-come-flux-models", create_if_missing=True)
MODEL_CACHE = "/vol/models"
MODEL_ID = "black-forest-labs/FLUX.1-dev"

image = (
    modal.Image.debian_slim(python_version="3.11")
    .env({"DEBIAN_FRONTEND": "noninteractive", "HF_HOME": MODEL_CACHE})
    .run_commands(
        "apt-get update -y && apt-get install -y --no-install-recommends git",
        "pip install --upgrade pip",
        "pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121",
        "pip install diffusers transformers accelerate sentencepiece protobuf fastapi[standard]",
    )
)


@app.cls(
    image=image,
    gpu="H100",           # 80GB VRAM — fastest generation, best for FLUX.1-dev
    timeout=300,
    container_idle_timeout=600,  # keep warm 10 min to avoid cold start cost
    volumes={MODEL_CACHE: model_volume},
    secrets=[modal.Secret.from_name("huggingface-secret")],  # HF_TOKEN for gated model
)
class FluxModel:
    @modal.enter()
    def load_model(self):
        """Load model once when container starts — cached in volume."""
        from diffusers import FluxPipeline
        import torch

        print(f"[flux] Loading {MODEL_ID} from {MODEL_CACHE}...")
        self.pipe = FluxPipeline.from_pretrained(
            MODEL_ID,
            torch_dtype=torch.bfloat16,
            cache_dir=MODEL_CACHE,
        )
        self.pipe = self.pipe.to("cuda")
        # H100 has 80GB VRAM — no need for cpu offload, runs full speed
        print("[flux] Model loaded.")

    @modal.web_endpoint(method="POST")
    def generate(self, item: dict) -> dict:
        import torch
        import base64
        import io

        prompt = item.get("prompt", "")
        if not prompt:
            return {"error": "Field 'prompt' is required."}

        # Clamp dimensions to multiples of 64
        width  = max(512, min(int(item.get("width",  1024)), 1440))
        height = max(512, min(int(item.get("height", 1024)), 1440))
        width  = (width  // 64) * 64
        height = (height // 64) * 64
        steps          = max(4,   min(int(item.get("steps", 28)),   50))
        guidance_scale = max(1.0, min(float(item.get("guidance_scale", 3.5)), 10.0))

        seed = item.get("seed")
        generator = None
        if seed is not None:
            generator = torch.Generator("cuda").manual_seed(int(seed))
        else:
            seed = torch.randint(0, 2**32 - 1, (1,)).item()
            generator = torch.Generator("cuda").manual_seed(seed)

        print(f"[flux] Generating {width}x{height}, steps={steps}, seed={seed}")
        print(f"[flux] Prompt: {prompt[:120]}...")

        result = self.pipe(
            prompt=prompt,
            width=width,
            height=height,
            num_inference_steps=steps,
            guidance_scale=guidance_scale,
            generator=generator,
        )
        img = result.images[0]

        buffer = io.BytesIO()
        img.save(buffer, format="PNG", optimize=False)
        buffer.seek(0)

        return {
            "image_base64": base64.b64encode(buffer.read()).decode(),
            "format": "png",
            "width": width,
            "height": height,
            "seed": int(seed),
        }
