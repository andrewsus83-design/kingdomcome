"""
Kingdom Come — FFmpeg Video Stitching on Modal.com
Deploy:  modal deploy video_app.py
URL:     https://{username}--kingdom-come-video-stitch.modal.run

POST body:
{
  "clips": [
    {"url": "https://assets.kingdomcomeapp.com/...", "duration": 3.0},
    {"url": "https://assets.kingdomcomeapp.com/...", "duration": 3.0}
  ],
  "audio_url": "https://assets.kingdomcomeapp.com/audio/...",  # optional
  "transition": "fade",   # "fade" | "slide" | "none"  (default: fade)
  "fps": 30,
  "output_format": "mp4"  # "mp4" | "webm"
}

Each clip can be:
  - A video URL (.mp4, .webm, .mov)
  - An image URL (.png, .jpg) — will be held for `duration` seconds

Returns:
{
  "video_base64": "...",
  "format": "mp4",
  "duration_seconds": 12.0,
  "clip_count": 4
}
"""

import modal

app = modal.App("kingdom-come-video")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .env({"DEBIAN_FRONTEND": "noninteractive"})
    .run_commands(
        "apt-get update -y && apt-get install -y --no-install-recommends "
        "ffmpeg curl wget ca-certificates",
        "pip install --upgrade pip",
        "pip install requests",
    )
)


@app.function(
    image=image,
    cpu=2,
    memory=2048,
    timeout=300,
    container_idle_timeout=300,
)
@modal.web_endpoint(method="POST")
def stitch(item: dict) -> dict:
    import subprocess
    import tempfile
    import os
    import base64
    import requests

    clips       = item.get("clips", [])
    audio_url   = item.get("audio_url")
    transition  = item.get("transition", "fade")   # fade | slide | none
    fps         = max(24, min(int(item.get("fps", 30)), 60))
    out_format  = item.get("output_format", "mp4")

    if not clips:
        return {"error": "Field 'clips' is required and must not be empty."}
    if len(clips) > 50:
        return {"error": "Maximum 50 clips per request."}

    with tempfile.TemporaryDirectory() as tmp:

        # ── 1. Download all clips ─────────────────────────────
        clip_paths = []
        for i, clip in enumerate(clips):
            url      = clip.get("url", "")
            duration = float(clip.get("duration", 3.0))
            duration = max(0.5, min(duration, 30.0))

            if not url:
                return {"error": f"Clip {i} missing 'url'."}

            ext = url.split("?")[0].rsplit(".", 1)[-1].lower()
            if ext not in ("mp4", "webm", "mov", "png", "jpg", "jpeg", "gif"):
                ext = "mp4"

            dest = os.path.join(tmp, f"clip_{i:03d}.{ext}")
            print(f"[video] Downloading clip {i}: {url[:80]}")
            r = requests.get(url, timeout=30)
            r.raise_for_status()
            with open(dest, "wb") as f:
                f.write(r.content)
            clip_paths.append((dest, ext, duration))

        # ── 2. Convert images → video clips ──────────────────
        video_paths = []
        for i, (path, ext, duration) in enumerate(clip_paths):
            out_clip = os.path.join(tmp, f"video_{i:03d}.mp4")
            if ext in ("png", "jpg", "jpeg"):
                # Still image held for duration seconds
                cmd = [
                    "ffmpeg", "-y", "-loop", "1",
                    "-i", path,
                    "-t", str(duration),
                    "-vf", f"scale=1080:1920:force_original_aspect_ratio=decrease,"
                           f"pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,"
                           f"fps={fps},format=yuv420p",
                    "-c:v", "libx264", "-preset", "fast", "-crf", "22",
                    out_clip,
                ]
            else:
                # Video clip — trim to duration
                cmd = [
                    "ffmpeg", "-y", "-i", path,
                    "-t", str(duration),
                    "-vf", f"scale=1080:1920:force_original_aspect_ratio=decrease,"
                           f"pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,"
                           f"fps={fps},format=yuv420p",
                    "-c:v", "libx264", "-preset", "fast", "-crf", "22",
                    "-an",  # strip original audio (we add ours later)
                    out_clip,
                ]
            subprocess.run(cmd, check=True, capture_output=True)
            video_paths.append(out_clip)

        # ── 3. Apply transitions & concatenate ────────────────
        final_video = os.path.join(tmp, "stitched.mp4")

        if len(video_paths) == 1:
            final_video = video_paths[0]

        elif transition == "none":
            # Simple concat — no transitions
            concat_list = os.path.join(tmp, "concat.txt")
            with open(concat_list, "w") as f:
                for vp in video_paths:
                    f.write(f"file '{vp}'\n")
            subprocess.run([
                "ffmpeg", "-y", "-f", "concat", "-safe", "0",
                "-i", concat_list,
                "-c", "copy", final_video,
            ], check=True, capture_output=True)

        else:
            # xfade transitions between clips
            fade_dur = 0.5  # seconds
            inputs = []
            for vp in video_paths:
                inputs += ["-i", vp]

            # Build xfade filter chain
            n = len(video_paths)
            durations = [float(clips[i].get("duration", 3.0)) for i in range(n)]
            filter_parts = []
            prev = "[0:v]"
            offset = durations[0] - fade_dur

            for i in range(1, n):
                tag = f"[v{i}]" if i < n - 1 else "[vout]"
                xfade_type = "fade" if transition == "fade" else "slideleft"
                filter_parts.append(
                    f"{prev}[{i}:v]xfade=transition={xfade_type}:"
                    f"duration={fade_dur}:offset={offset:.3f}{tag}"
                )
                prev = f"[v{i}]"
                if i < n - 1:
                    offset += durations[i] - fade_dur

            filter_complex = ";".join(filter_parts)
            cmd = (
                ["ffmpeg", "-y"] + inputs +
                ["-filter_complex", filter_complex,
                 "-map", "[vout]",
                 "-c:v", "libx264", "-preset", "fast", "-crf", "22",
                 final_video]
            )
            result = subprocess.run(cmd, capture_output=True)
            if result.returncode != 0:
                # Fallback to simple concat on xfade error
                print("[video] xfade failed, falling back to concat:", result.stderr.decode()[:300])
                concat_list = os.path.join(tmp, "concat.txt")
                with open(concat_list, "w") as f:
                    for vp in video_paths:
                        f.write(f"file '{vp}'\n")
                subprocess.run([
                    "ffmpeg", "-y", "-f", "concat", "-safe", "0",
                    "-i", concat_list,
                    "-c", "copy", final_video,
                ], check=True, capture_output=True)

        # ── 4. Add audio track ────────────────────────────────
        output_path = os.path.join(tmp, f"output.{out_format}")

        if audio_url:
            audio_path = os.path.join(tmp, "audio.mp3")
            print(f"[video] Downloading audio: {audio_url[:80]}")
            r = requests.get(audio_url, timeout=30)
            r.raise_for_status()
            with open(audio_path, "wb") as f:
                f.write(r.content)

            subprocess.run([
                "ffmpeg", "-y",
                "-i", final_video,
                "-i", audio_path,
                "-c:v", "copy",
                "-c:a", "aac", "-b:a", "192k",
                "-shortest",  # trim to shortest (video or audio)
                output_path,
            ], check=True, capture_output=True)
        else:
            subprocess.run([
                "ffmpeg", "-y",
                "-i", final_video,
                "-c:v", "copy",
                output_path,
            ], check=True, capture_output=True)

        # ── 5. Get duration of final output ──────────────────
        probe = subprocess.run([
            "ffprobe", "-v", "quiet", "-print_format", "json",
            "-show_format", output_path,
        ], capture_output=True, text=True)

        duration_seconds = 0.0
        try:
            import json
            info = json.loads(probe.stdout)
            duration_seconds = float(info["format"]["duration"])
        except Exception:
            pass

        # ── 6. Read and return ────────────────────────────────
        with open(output_path, "rb") as f:
            video_bytes = f.read()

        print(f"[video] Done. {len(video_paths)} clips, {duration_seconds:.1f}s, {len(video_bytes)//1024}KB")

        return {
            "video_base64": base64.b64encode(video_bytes).decode(),
            "format": out_format,
            "duration_seconds": round(duration_seconds, 2),
            "clip_count": len(video_paths),
        }
