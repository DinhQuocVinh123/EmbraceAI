"""Kiểm chứng lời đọc nằm đúng chỗ trong video đã trộn.

Cách kiểm: đo năng lượng dải tiếng nói theo từng khung 100 ms, rồi so mức
trung bình trong các khung có phụ đề với các khung không có. Nếu lời đọc khớp,
hai con số phải chênh nhau rõ rệt. Một phép đối chứng chạy kèm: dời toàn bộ
mốc phụ đề đi 7 giây rồi đo lại — nếu bản dời cũng cho kết quả tương đương thì
phép đo vô nghĩa, và kết luận bị bác.
"""
import io
import json
import os
import subprocess
import sys

import numpy as np

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Phần nặng — bản video câm gốc, mô hình giọng, dải lời đọc — để ngoài
# repo app: build/ bị flutter clean xoá, còn assets/ thì bị đóng vào APK.
VOICE = os.environ.get("EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice")

FFMPEG = os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages"
    r"\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"
    r"\ffmpeg-9.0.1-full_build\bin\ffmpeg.exe")

SR = 16000
HOP = 0.1
SHIFT = 7.0
TOTAL = 480.0


def load(path):
    r = subprocess.run(
        [FFMPEG, "-v", "error", "-i", path, "-map", "0:a:0", "-ac", "1",
         "-ar", str(SR), "-f", "s16le", "-"],
        capture_output=True)
    return np.frombuffer(r.stdout, dtype="<i2").astype(np.float32) / 32768.0


def envelope(x):
    """Năng lượng dải 300–3400 Hz, theo khung 100 ms."""
    n = int(HOP * SR)
    frames = len(x) // n
    x = x[:frames * n].reshape(frames, n)
    spec = np.abs(np.fft.rfft(x * np.hanning(n), axis=1))
    freqs = np.fft.rfftfreq(n, 1 / SR)
    band = (freqs >= 300) & (freqs <= 3400)
    return spec[:, band].mean(axis=1), frames


def mask_from(caps, frames, shift=0.0):
    m = np.zeros(frames, dtype=bool)
    for c in caps:
        a = (c["start"] + shift) % TOTAL
        b = a + min(c["room"], 6.0)
        m[int(a / HOP):int(b / HOP)] = True
    return m


def report(name, path, caps):
    env, frames = envelope(load(path))
    on = mask_from(caps, frames)
    off = ~mask_from(caps, frames)
    shifted = mask_from(caps, frames, SHIFT)

    def db(mask):
        v = env[mask]
        return 20 * np.log10(max(float(v.mean()), 1e-9))

    real = db(on) - db(off)
    control = db(shifted) - db(~shifted)
    print(f"{name}")
    print(f"  khi co phu de : {db(on):7.2f} dB")
    print(f"  khi khong co   : {db(off):7.2f} dB")
    print(f"  chenh lech     : {real:7.2f} dB   <- can phai lon")
    print(f"  doi chung (+{SHIFT:.0f}s): {control:7.2f} dB   <- can phai nho")
    ok = real > 6.0 and real > control + 4.0
    print("  KET LUAN       :", "khop" if ok else "KHONG KHOP")
    return ok


def main():
    caps = json.load(io.open(VOICE + "/captions.json", encoding="utf-8"))
    results = [
        report("canh que", "assets/video/meditation_8min.mp4", caps),
        report("canh bien", "assets/video/beach_8min.mp4", caps),
    ]
    print()
    print("tat ca khop" if all(results) else "CO BAN KHONG KHOP")


main()
