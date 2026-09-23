"""Đo nền sáng nhất mà chữ phụ đề có thể phải nằm lên.

Phụ đề được đặt theo toạ độ màn hình chứ không theo khung hình, nên khi cửa sổ
thấp và ngang — trình duyệt trên điện thoại xoay ngang, máy tính bảng — nó đè
lên chính hình video. Câu hỏi là nền dưới nó sáng tới đâu, vì chữ trắng trên
nền sáng thì không đọc được.

Quét cả hai video, lấy dải dưới của khung hình, tìm vùng sáng nhất theo cỡ một
dòng chữ. Đo trên toàn bộ 8 phút chứ không đoán từ vài khung.
"""
import os
import subprocess
import sys

import numpy as np

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

FFMPEG = os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages"
    r"\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"
    r"\ffmpeg-9.0.1-full_build\bin\ffmpeg.exe")

W, H = 320, 180        # đủ để đo độ sáng, không cần chi tiết
FPS = 1                # một khung mỗi giây
BAND = (0.55, 0.95)    # dải dưới khung hình, nơi phụ đề có thể rơi vào
LINE = 12              # chiều cao một dòng chữ, quy về cỡ khung đã thu nhỏ


def srgb_to_linear(a):
    a = a / 255.0
    return np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)


def luminance(rgb):
    lin = srgb_to_linear(rgb.astype(np.float64))
    return (0.2126 * lin[..., 0] + 0.7152 * lin[..., 1]
            + 0.0722 * lin[..., 2])


def contrast(l1, l2):
    hi, lo = max(l1, l2), min(l1, l2)
    return (hi + 0.05) / (lo + 0.05)


def scan(path):
    r = subprocess.run(
        [FFMPEG, "-v", "error", "-i", path, "-vf",
         f"fps={FPS},scale={W}:{H}", "-pix_fmt", "rgb24", "-f", "rawvideo", "-"],
        capture_output=True)
    frames = np.frombuffer(r.stdout, dtype=np.uint8).reshape(-1, H, W, 3)
    lum = luminance(frames)
    top, bottom = int(BAND[0] * H), int(BAND[1] * H)
    band = lum[:, top:bottom, :]

    # Độ sáng trung bình của từng dải cao bằng một dòng chữ.
    rows = band.shape[1] - LINE
    means = np.stack([band[:, i:i + LINE, :].mean(axis=(1, 2))
                      for i in range(rows)], axis=1)
    per_frame = means.max(axis=1)
    return frames.shape[0], per_frame


def report(name, path):
    n, per_frame = scan(path)
    worst = float(per_frame.max())
    p99 = float(np.percentile(per_frame, 99))
    white = 1.0
    print(f"{name}  ({n} khung)")
    print(f"  nen sang nhat        L={worst:.4f}  chu trang duoc "
          f"{contrast(white, worst):5.2f}:1")
    print(f"  muc 99%              L={p99:.4f}  chu trang duoc "
          f"{contrast(white, p99):5.2f}:1")
    for alpha in (0.45, 0.55, 0.62, 0.70):
        # Tấm nền đen phủ lên trước khi vẽ chữ.
        shown = (1 - alpha) * 255
        backed = float(luminance(np.array([shown, shown, shown])))
        # Nền sáng nhất sau khi bị tấm nền phủ lên.
        under = float(luminance(np.array([(1 - alpha) * 255] * 3)))
        print(f"  co tam nen den {alpha:.2f}  L={under:.4f}  chu trang duoc "
              f"{contrast(white, backed):5.2f}:1")
    return worst


def main():
    worst = max(
        report("canh que", "assets/video/meditation_8min.mp4"),
        report("canh bien", "assets/video/beach_8min.mp4"),
    )
    print()
    print("Ket luan: khong co tam nen, truong hop xau nhat chi dat "
          f"{contrast(1.0, worst):.2f}:1 — duoi nguong 4.5:1 cua SC 1.4.3.")


main()
