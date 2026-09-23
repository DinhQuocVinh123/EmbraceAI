"""Đo độ mờ và màu của tấm nền sau chữ nung cứng.

Chữ trong video gốc nằm trên một tấm chữ nhật xám mờ. Tấm đó phủ lên hình theo
đúng công thức trộn alpha:

    thấy được = (1 - a) * nền_gốc + a * màu_tấm

Nếu đo được `a` và `màu_tấm` thì lấy lại được nền gốc ở mọi điểm không bị nét
chữ che — tức là gỡ được tấm nền ra mà không mất gì.

Cách đo: lấy các cặp điểm nằm sát hai bên mép ngang của tấm. Hai điểm chỉ cách
nhau vài hàng nên nền phía sau gần như giống nhau; điểm ngoài cho `nền_gốc`,
điểm trong cho `thấy được`. Hồi quy tuyến tính qua hàng nghìn cặp như vậy cho
hệ số góc `1 - a` và tung độ gốc `a * màu_tấm`.
"""
import os
import subprocess
import sys

import numpy as np

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

VOICE = os.environ.get("EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice")
FFMPEG = os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages"
    r"\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"
    r"\ffmpeg-9.0.1-full_build\bin\ffmpeg.exe")
SOURCE = VOICE + "/masters/meditation_8min.mp4"
W, H = 1280, 720

# Mép ngang của hai tấm, đo bằng measure_text_bands.py.
CAPTION_TOP, CAPTION_BOTTOM = 576, 663
LABEL_TOP, LABEL_BOTTOM = 25, 65
GAP = 3          # tránh vùng nhoè ở đúng mép
SAMPLES = 24     # số khung lấy mẫu


def frames(n):
    step = max(1, 480 // n)
    r = subprocess.run(
        [FFMPEG, "-v", "error", "-i", SOURCE, "-vf", f"fps=1/{step}",
         "-pix_fmt", "rgb24", "-f", "rawvideo", "-"],
        capture_output=True)
    return np.frombuffer(r.stdout, dtype=np.uint8).reshape(-1, H, W, 3)


def fit(f, top, bottom, x0, x1, name):
    outside, inside = [], []
    for edge, out_y, in_y in ((top, top - GAP, top + GAP),
                              (bottom, bottom + GAP, bottom - GAP)):
        outside.append(f[:, out_y, x0:x1, :].reshape(-1, 3))
        inside.append(f[:, in_y, x0:x1, :].reshape(-1, 3))
    bg = np.concatenate(outside).astype(np.float64)
    obs = np.concatenate(inside).astype(np.float64)

    # Bỏ các cặp có nét chữ hoặc mép vật thể chen vào: chúng phá quan hệ tuyến
    # tính. Lọc bằng phần dư sau một lần khớp thô.
    keep = np.ones(len(bg), dtype=bool)
    alpha = colour = None
    for _ in range(3):
        a, c = [], []
        for ch in range(3):
            slope, intercept = np.polyfit(bg[keep, ch], obs[keep, ch], 1)
            a.append(1 - slope)
            c.append(intercept / max(1 - slope, 1e-6))
        alpha = float(np.mean(a))
        colour = np.array(c)
        pred = (1 - alpha) * bg + alpha * colour
        err = np.abs(pred - obs).max(axis=1)
        keep = err < np.percentile(err, 70)

    print(f"{name}: a = {alpha:.4f}   mau tam = "
          f"({colour[0]:.1f}, {colour[1]:.1f}, {colour[2]:.1f})   "
          f"dung {keep.sum()} cap")
    return alpha, colour


def main():
    f = frames(SAMPLES)
    print("so khung lay mau:", len(f))
    fit(f, CAPTION_TOP, CAPTION_BOTTOM, 200, 1080, "tam phu de")
    fit(f, LABEL_TOP, LABEL_BOTTOM, 40, 380, "tam nhan tren")


main()
