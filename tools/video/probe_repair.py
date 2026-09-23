"""Kiểm xem có thể vá vùng chữ bằng khung sạch lân cận không.

Ý tưởng: tấm phụ đề chỉ hiện khi có câu, giữa hai câu thì vùng đó sạch. Nếu
nền phía sau đứng yên trong vài giây thì lấy thẳng vùng sạch của khung gần
nhất dán vào là khôi phục được nguyên vẹn — kể cả cái bàn và ly nước mà bản
cắt đã làm mất.

Ba câu hỏi cần trả lời trước khi bắt tay:

  1. Mỗi giây có tấm phụ đề hay không?
  2. Nhãn "Beat N" ở góc trên có lúc nào vắng mặt không?
  3. Vùng dưới đứng yên tới mức nào? Đo bằng cách so hai khung sạch cách nhau
     vài giây — nếu chúng gần như trùng nhau thì vá được.
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

CAPTION = slice(570, 670)
LABEL = slice(20, 70)
LABEL_X = slice(28, 470)


def load():
    r = subprocess.run(
        [FFMPEG, "-v", "error", "-i", SOURCE, "-vf", "fps=1",
         "-pix_fmt", "gray", "-f", "rawvideo", "-"],
        capture_output=True)
    return np.frombuffer(r.stdout, dtype=np.uint8).reshape(-1, H, W)


def has_text(band, floor=232, need=60):
    """Có nét chữ trắng trong dải này không."""
    return ((band >= floor).sum(axis=(1, 2)) >= need)


def main():
    f = load()
    n = len(f)
    print("so khung:", n)

    cap = has_text(f[:, CAPTION, :])
    lab = has_text(f[:, LABEL, LABEL_X], floor=225, need=25)
    print(f"giay co phu de : {cap.sum()}/{n}  ({cap.mean():.0%})")
    print(f"giay co nhan   : {lab.sum()}/{n}  ({lab.mean():.0%})")

    clean = np.where(~cap)[0]
    print("khoang sach dai nhat lien tuc:",
          max((len(g) for g in np.split(clean, np.where(np.diff(clean) != 1)[0] + 1)),
              default=0), "giay")

    # Khoang cach toi khung sach gan nhat, cho moi giay co phu de.
    if len(clean):
        d = np.abs(np.where(cap)[0][:, None] - clean[None, :]).min(axis=1)
        print(f"khoang cach toi khung sach: trung binh {d.mean():.1f}s, "
              f"xa nhat {d.max()}s")

    # Vung duoi dung yen toi dau? So cac cap khung sach cach nhau 1..8 giay.
    print()
    print("do lech vung duoi giua hai khung sach (thang do 0-255):")
    for gap in (1, 2, 4, 8):
        diffs = []
        for i in clean:
            j = i + gap
            if j in set(clean.tolist()):
                a = f[i, CAPTION, :].astype(np.int16)
                b = f[j, CAPTION, :].astype(np.int16)
                diffs.append(np.abs(a - b).mean())
        if diffs:
            print(f"   cach {gap}s: lech trung binh {np.mean(diffs):5.2f}, "
                  f"xau nhat {np.max(diffs):5.2f}  ({len(diffs)} cap)")


main()
