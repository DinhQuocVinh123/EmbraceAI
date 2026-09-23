"""Cắt bỏ chữ nung cứng khỏi video cảnh quê, thay vì phủ lớp tối lên nó.

Video gốc có nhãn "Beat N · ..." ở góc trên trái và phụ đề tiếng Anh ở dưới.
Trước đây app phủ hai dải tối lên để giấu chúng — hình tối đi hai đầu, trông
như bị rọi đèn vào giữa, mà chữ vẫn lấp ló dưới lớp phủ và chồng lên phụ đề
do app tự vẽ.

Cắt hẳn hai dải đó đi thì được nhiều hơn mất. Vùng hình còn lại sáng nguyên,
không lớp phủ nào cả — và thật ra người dùng còn thấy *nhiều* hình hơn trước:
lớp phủ cũ đã ăn mất từ 18% trên xuống và từ 66% dưới lên, chỉ chừa khoảng
48% ở giữa, trong khi bản cắt giữ lại gần 70%.

Cắt cũng dứt điểm một mâu thuẫn khác: đoạn 1:36–2:06 có chữ nung cứng mang
lời văn cũ, không khớp với giọng đọc hiện tại.

Mốc cắt đo bằng `measure_text_bands.py` và dò mép tấm nền theo cột: nhãn trên
chiếm hàng 25–65, tấm phụ đề chiếm hàng 576–663.
"""
import os
import subprocess
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

VOICE = os.environ.get("EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice")
FFMPEG = os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages"
    r"\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"
    r"\ffmpeg-9.0.1-full_build\bin\ffmpeg.exe")
FFPROBE = FFMPEG.replace("ffmpeg.exe", "ffprobe.exe")

SOURCE = VOICE + "/masters/meditation_8min.mp4"
OUTPUT = VOICE + "/masters/meditation_8min_clean.mp4"

WIDTH = 1280
# Chừa 5 hàng đệm mỗi đầu so với mép tấm nền đo được.
TOP = 70
HEIGHT = 500


def main():
    if not os.path.exists(SOURCE):
        raise SystemExit("thieu ban goc: " + SOURCE)

    r = subprocess.run(
        [FFMPEG, "-v", "error", "-stats", "-y", "-i", SOURCE,
         "-vf", f"crop={WIDTH}:{HEIGHT}:0:{TOP}",
         "-an",                       # tieng se duoc tron o buoc sau
         "-c:v", "libx264", "-crf", "22", "-preset", "medium",
         "-pix_fmt", "yuv420p", "-movflags", "+faststart", OUTPUT],
        capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode:
        print(r.stderr[-2000:])
        raise SystemExit("ffmpeg loi")

    p = subprocess.run(
        [FFPROBE, "-v", "error", "-select_streams", "v:0", "-show_entries",
         "stream=width,height,nb_frames:format=duration,size",
         "-of", "default=nw=1", OUTPUT],
        capture_output=True, text=True, encoding="utf-8", errors="replace")
    print(p.stdout.strip())
    print("ty le khung:", round(WIDTH / HEIGHT, 2), ": 1")


main()
