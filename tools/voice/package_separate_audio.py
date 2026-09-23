"""Package narration-only videos and independently selectable ambience."""

import os
import shutil
import subprocess
import sys


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
VOICE = os.environ.get("EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice")
FFMPEG = shutil.which("ffmpeg")
FFPROBE = shutil.which("ffprobe")
NARRATION = os.path.join(VOICE, "narration.wav")
AUDIO_DIR = os.path.join(ROOT, "assets", "audio")
VIDEO_DIR = os.path.join(ROOT, "assets", "video")

VIDEO_ASSETS = {
    "meditation_narration_8min.mp4": "meditation_8min.mp4",
    "beach_narration_8min.mp4": "beach_8min.mp4",
}
AMBIENCE = {
    "ambient_countryside.m4a": os.path.join(VOICE, "ambient_countryside.wav"),
    "ambient_ocean.m4a": os.path.join(VOICE, "ambient_beach.wav"),
    "ambient_rain.m4a": os.path.join(VOICE, "ambient_rain.wav"),
}

VOICE_FILTER = (
    "[1:a]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,"
    "volume=1.6,alimiter=limit=0.95[voice]"
)
AMBIENCE_FILTER = (
    "[1:a]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,"
    "volume=1.6[voice_key];"
    "[0:a]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[amb];"
    "[amb][voice_key]sidechaincompress=threshold=0.02:ratio=6:attack=30:"
    "release=700:makeup=1,volume=12dB,alimiter=limit=0.95[aout]"
)


def run(args):
    result = subprocess.run(
        args, capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    if result.returncode:
        print(result.stderr[-3000:])
        raise SystemExit("media packaging failed")
    return result.stdout


def probe(path):
    return run(
        [
            FFPROBE,
            "-v",
            "error",
            "-show_entries",
            "format=duration,size:stream=codec_type,codec_name,width,height,channels",
            "-of",
            "default=nw=1",
            path,
        ]
    ).strip().replace("\n", " ")


def package_video(name, source_name):
    source = os.path.join(VIDEO_DIR, source_name)
    target = os.path.join(VIDEO_DIR, name)
    temporary = target + ".tmp.mp4"
    run(
        [
            FFMPEG,
            "-v",
            "error",
            "-y",
            "-i",
            source,
            "-i",
            NARRATION,
            "-filter_complex",
            VOICE_FILTER,
            "-map",
            "0:v:0",
            "-map",
            "[voice]",
            "-c:v",
            "copy",
            "-c:a",
            "aac",
            "-b:a",
            "96k",
            "-t",
            "480",
            "-movflags",
            "+faststart",
            temporary,
        ]
    )
    os.replace(temporary, target)
    print(name, probe(target))


def package_ambience(name, source):
    target = os.path.join(AUDIO_DIR, name)
    temporary = target + ".tmp.m4a"
    run(
        [
            FFMPEG,
            "-v",
            "error",
            "-y",
            "-i",
            source,
            "-i",
            NARRATION,
            "-filter_complex",
            AMBIENCE_FILTER,
            "-map",
            "[aout]",
            "-c:a",
            "aac",
            "-b:a",
            "96k",
            "-t",
            "480",
            "-movflags",
            "+faststart",
            temporary,
        ]
    )
    os.replace(temporary, target)
    print(name, probe(target))


def main():
    if FFMPEG is None or FFPROBE is None:
        raise SystemExit("ffmpeg and ffprobe are required")
    os.makedirs(AUDIO_DIR, exist_ok=True)
    requested = set(sys.argv[1:])
    for name, source_name in VIDEO_ASSETS.items():
        if not requested or name in requested:
            package_video(name, source_name)
    for name, source in AMBIENCE.items():
        if not requested or name in requested:
            if not os.path.exists(source):
                raise SystemExit("missing ambience source: " + source)
            package_ambience(name, source)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    main()
