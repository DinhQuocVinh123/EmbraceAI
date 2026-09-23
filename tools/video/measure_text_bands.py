"""Đo chính xác hai dải chữ nung cứng trong video cảnh quê.

Video gốc có nhãn "Beat N · ..." ở góc trên trái và phụ đề tiếng Anh ở dưới,
cả hai nằm trên một tấm nền xám mờ. App đang phủ hai dải tối lên để giấu chúng
— cách đó làm hình tối đi hai đầu mà chữ vẫn lấp ló.

Muốn cắt bỏ thay vì che thì phải biết chúng nằm ở đâu, và phải biết chắc chứ
không ước lượng bằng mắt trên vài khung: chữ dài ngắn khác nhau theo câu, và
nhãn dài ngắn khác nhau theo beat.

Cách đo: quét nhiều khung trải đều cả 8 phút, đếm theo từng hàng số điểm ảnh
trắng gần như tuyệt đối — đó là nét chữ. Hàng nào có chữ ở bất kỳ khung nào
đều bị tính vào dải phải bỏ.
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

SOURCE = os.environ.get(
    "EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice") + "/masters/meditation_8min.mp4"
W, H = 1280, 720
FPS = 1            # một khung mỗi giây, đủ để bắt mọi câu phụ đề
WHITE = 236        # nét chữ trắng; nền trời sáng nhất trong phim vẫn dưới mức này
MIN_RUN = 40       # số điểm trắng tối thiểu trên một hàng để coi là có chữ


def frames():
    r = subprocess.run(
        [FFMPEG, "-v", "error", "-i", SOURCE, "-vf", f"fps={FPS}",
         "-pix_fmt", "rgb24", "-f", "rawvideo", "-"],
        capture_output=True)
    return np.frombuffer(r.stdout, dtype=np.uint8).reshape(-1, H, W, 3)


def main():
    f = frames()
    print("so khung do:", len(f))

    white = (f >= WHITE).all(axis=3)          # (n, H, W)
    per_row = white.sum(axis=2)               # (n, H)
    rows_with_text = (per_row >= MIN_RUN).any(axis=0)

    hits = np.where(rows_with_text)[0]
    # Hai cụm: nhãn trên và phụ đề dưới. Tách ở giữa khung.
    top = hits[hits < H // 2]
    bottom = hits[hits >= H // 2]

    print(f"nhan tren : hang {top.min()}–{top.max()}  "
          f"({top.min() / H:.1%}–{top.max() / H:.1%})")
    print(f"phu de duoi: hang {bottom.min()}–{bottom.max()}  "
          f"({bottom.min() / H:.1%}–{bottom.max() / H:.1%})")

    # Tấm nền xám rộng hơn nét chữ. Nới ra tới khi hàng trở lại giống hàng
    # kế bên — mép tấm nền tạo một bậc rõ trong độ sáng trung bình.
    mean_rows = f.mean(axis=(0, 2, 3))
    def edge(start, direction, limit):
        prev = mean_rows[start]
        r = start
        for _ in range(limit):
            nxt = r + direction
            if not (0 <= nxt < H):
                break
            if abs(mean_rows[nxt] - prev) > 2.0:
                return nxt
            prev = mean_rows[nxt]
            r = nxt
        return r

    top_edge = edge(int(top.max()), +1, 40)
    bottom_edge = edge(int(bottom.min()), -1, 40)
    print(f"mep duoi cua tam nen tren : {top_edge}")
    print(f"mep tren cua tam nen duoi : {bottom_edge}")

    keep_top = top_edge + 4
    keep_bottom = bottom_edge - 4
    height = keep_bottom - keep_top
    height -= height % 2       # chieu cao chan cho bo ma hoa
    print()
    print(f"=> cat giu hang {keep_top}..{keep_top + height} "
          f"= {W}x{height}, ty le {W / height:.2f}:1")
    print(f"   giu lai {height / H:.1%} chieu cao")
    print(f"   crop={W}:{height}:0:{keep_top}")


main()
