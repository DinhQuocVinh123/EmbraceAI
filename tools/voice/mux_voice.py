"""Trộn âm nền và lời đọc vào video, giữ nguyên phần hình.

Mỗi bối cảnh có âm nền riêng: cảnh quê dùng nhạc nền đi kèm video gốc, cảnh
biển dùng dải sóng dựng ở `make_beach_ambient.py`. Âm nền được nén xuống mỗi
khi có tiếng nói (sidechain) rồi trả lại, nên lời nghe rõ mà nền không bị hạ
đều suốt 8 phút. Phần hình chỉ được chép lại chứ không mã hoá lại: hình không
mất thêm chất lượng, và việc trộn xong trong vài giây thay vì vài chục phút.

Nguồn hình luôn là bản gốc ngoài repo, không bao giờ là file đang nằm trong
`assets` — trộn đè lên file đã có tiếng sẽ thành hai giọng chồng nhau, và
không lấy lại được bản sạch. Phần tiếng của bản gốc bị bỏ qua hoàn toàn, âm
nền luôn lấy từ file rời, nên chạy lại bao nhiêu lần cũng ra cùng một kết quả.
"""
import os
import shutil
import subprocess
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Phần nặng — bản video gốc, mô hình giọng, dải lời đọc, âm nền — để ngoài
# repo app: build/ bị flutter clean xoá, còn assets/ thì bị đóng vào APK.
VOICE = os.environ.get("EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice")

FFMPEG = os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages"
    r"\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"
    r"\ffmpeg-9.0.1-full_build\bin\ffmpeg.exe")
FFPROBE = FFMPEG.replace("ffmpeg.exe", "ffprobe.exe")

MASTERS = VOICE + "/masters"
NARRATION = VOICE + "/narration.wav"

# (file trong assets, tên gọi, bản hình gốc, file âm nền)
#
# Cảnh quê dùng bản Full HD không phụ đề, giữ nguyên khung hình.
# Có thể chỉ định nguồn khác qua EMBRACE_COUNTRYSIDE_VIDEO.
COUNTRYSIDE = os.environ.get(
    "EMBRACE_COUNTRYSIDE_VIDEO",
    os.path.join(os.path.dirname(VOICE), "Eight_Minutes_v2_no_subtitles.mp4"))
SCENES = [
    ("meditation_8min.mp4", "canh que",
     COUNTRYSIDE, VOICE + "/ambient_countryside.wav"),
    ("beach_8min.mp4", "canh bien",
     "beach_8min.mp4", VOICE + "/ambient_beach.wav"),
]

# Đầu vào: 0 = video (chỉ lấy hình), 1 = âm nền, 2 = lời đọc.
FILTER = (
    "[2:a]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,"
    "volume=1.6[voice];"
    "[voice]asplit=2[voice_mix][voice_key];"
    "[1:a]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo"
    "[amb];"
    # Nền tự lùi lại khi có lời, tự trở về khi im.
    "[amb][voice_key]sidechaincompress=threshold=0.02:ratio=6:attack=30:"
    "release=700:makeup=1[ducked];"
    "[ducked][voice_mix]amix=inputs=2:duration=first:dropout_transition=0,"
    "alimiter=limit=0.95[aout]")


def run(args):
    r = subprocess.run(args, capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    if r.returncode:
        print(r.stderr[-2500:])
        raise SystemExit("ffmpeg loi")
    return r


def probe(path):
    r = run([FFPROBE, "-v", "error", "-show_entries",
             "format=duration,size:stream=codec_type,codec_name",
             "-of", "default=nw=1", path])
    return r.stdout.strip().replace("\n", " ")


def main():
    os.makedirs(MASTERS, exist_ok=True)
    for asset, name, master_name, ambient in SCENES:
        src = os.path.join("assets/video", asset)
        master = os.path.join(MASTERS, master_name)
        if not os.path.exists(master):
            raise SystemExit("thieu ban hinh goc: " + master)
        if not os.path.exists(ambient):
            raise SystemExit("thieu am nen: " + ambient)

        out = os.path.join(VOICE, "narrated_" + asset)
        run([FFMPEG, "-v", "error", "-y",
             "-i", master, "-i", ambient, "-i", NARRATION,
             "-filter_complex", FILTER,
             "-map", "0:v:0", "-map", "[aout]",
             "-c:v", "copy", "-c:a", "aac", "-b:a", "128k",
             "-movflags", "+faststart", out])
        shutil.move(out, src)
        print(f"{name:12s} {probe(src)}")


main()
