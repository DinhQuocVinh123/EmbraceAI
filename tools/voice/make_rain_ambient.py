"""Generate an eight-minute, license-free gentle-rain ambience."""

import os
import shutil
import subprocess
import sys


VOICE = os.environ.get("EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice")
FFMPEG = shutil.which("ffmpeg")
OUT = os.path.join(VOICE, "ambient_rain.wav")


def main():
    if FFMPEG is None:
        raise SystemExit("ffmpeg is not available")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    left = "anoisesrc=color=pink:amplitude=0.10:duration=480:sample_rate=44100:seed=20260922"
    right = "anoisesrc=color=pink:amplitude=0.10:duration=480:sample_rate=44100:seed=20260923"
    filter_graph = (
        "[0:a]highpass=f=140,lowpass=f=7000,"
        "volume='0.575*(0.94+0.06*sin(2*PI*t/37))':eval=frame[l];"
        "[1:a]highpass=f=180,lowpass=f=8200,"
        "volume='0.575*(0.94+0.06*sin(2*PI*t/43))':eval=frame[r];"
        "[l][r]amerge=inputs=2,pan=stereo|c0=c0|c1=c1,"
        "afade=t=in:st=0:d=4,afade=t=out:st=476:d=4,"
        "alimiter=limit=0.8[out]"
    )
    command = [
        FFMPEG,
        "-v",
        "error",
        "-y",
        "-f",
        "lavfi",
        "-i",
        left,
        "-f",
        "lavfi",
        "-i",
        right,
        "-filter_complex",
        filter_graph,
        "-map",
        "[out]",
        "-c:a",
        "pcm_s16le",
        OUT,
    ]
    subprocess.run(command, check=True)
    print(OUT)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    main()
