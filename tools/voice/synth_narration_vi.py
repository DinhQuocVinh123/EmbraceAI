"""Dựng dải lời đọc tiếng Việt dài 8 phút, khớp đúng mốc phụ đề của kịch bản.

Giống synth_narration.py (tiếng Anh): mỗi câu được đọc riêng rồi đặt vào đúng
giây nó hiện trên màn hình. Câu nào dài hơn khoảng trống tới câu kế thì đọc
nhanh lại vừa đủ, và chỉ câu đó.

Khác ở hai chỗ:
 - Giọng là VieNeu-TTS v3 Turbo (Apache 2.0, chạy offline trên CPU; các giọng
   có sẵn do chính người đọc đồng ý cho dùng). Piper cũng có giọng tiếng Việt
   nhưng nghe quá máy cho một bài thư giãn. Mô hình tự gắn một dấu nước không
   nghe thấy được để đánh dấu đây là giọng máy tạo, và ta giữ nguyên dấu đó.
 - Kết quả là một file riêng, assets/audio/narration_vi.m4a, không trộn vào
   video: khi người dùng chọn tiếng Việt, app tắt tiếng video và phát file này
   song song. Giọng tiếng Anh trong video vẫn y nguyên.

Cài một lần, vào môi trường riêng ngoài repo:
  py -3.11 -m venv D:\\VideoProjects\\voice\\venv-vieneu
  D:\\VideoProjects\\voice\\venv-vieneu\\Scripts\\python -m pip install vieneu

Dùng (từ D:\\EmbraceAI, sau extract_captions.py):
  D:\\VideoProjects\\voice\\venv-vieneu\\Scripts\\python tools\\voice\\synth_narration_vi.py ["Tên giọng"]
"""
import io
import json
import os
import re
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Phần nặng — mô hình giọng, dải lời đọc gốc — để ngoài repo app.
VOICE = os.environ.get("EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice")

OUT = "assets/audio/narration_vi.m4a"
DEFAULT_VOICE = "Kim Thanh"   # nữ, giọng Nam, đọc truyện: chậm, ít đọc sai nhất
TOTAL = 480.0
RATE = 48_000
# Đo từ giọng tiếng Anh trong video (ebur128), để thanh âm lượng giọng đọc
# trong app cho cảm giác như nhau ở cả hai ngôn ngữ.
TARGET_LUFS = -14.7
PEAK = 0.89          # trần đỉnh, như bản tiếng Anh
MAX_TEMPO = 1.2      # nhanh hơn mức này giọng bắt đầu nghe hối
FADE_MS = 25         # chống tiếng tách ở đầu và cuối mỗi câu
TRIES = 3
# Số tiếng mỗi giây. Ngoài khoảng này gần như chắc chắn mô hình đã đọc sót
# hoặc nói thêm, nên đọc lại câu đó.
PACE = (1.8, 6.5)


def load_tts():
    """ONNX Runtime trên Windows từ chối đọc file .data qua symlink trong bộ nhớ
    đệm của Hugging Face, nên tải mô hình về thư mục thường rồi trỏ engine vào."""
    from huggingface_hub import snapshot_download
    from vieneu import Vieneu
    from vieneu._v3_turbo_engine import onnx_runtime_lite as engine

    local = Path(VOICE) / "models"

    def fetch(repo, files, subfolder):
        target = local / repo.replace("/", "__")
        patterns = [f"{subfolder}/{f}" if subfolder else f for f in files]
        snapshot_download(repo, allow_patterns=patterns, local_dir=target)
        return target / subfolder if subfolder else target

    engine.OnnxV3LiteEngine._fetch = staticmethod(fetch)
    return Vieneu()


def syllables(text):
    return len(re.findall(r"\w+", text))


def trim(audio, floor=0.01, margin_ms=30):
    """Bỏ khoảng lặng hai đầu, để câu bắt đầu đúng giây phụ đề hiện ra."""
    loud = np.flatnonzero(np.abs(audio) > floor * max(float(np.max(np.abs(audio))), 1e-9))
    if not len(loud):
        return audio
    margin = int(margin_ms * RATE / 1000)
    return audio[max(0, loud[0] - margin):loud[-1] + margin]


def speak(tts, voice, text, seed):
    """Đọc một câu; đọc lại nếu tốc độ cho thấy mô hình đọc sót hay nói thêm."""
    for attempt in range(TRIES):
        np.random.seed(seed * 10 + attempt)   # cùng kịch bản thì ra cùng giọng
        audio = trim(tts.infer(text, voice=voice).astype(np.float32))
        pace = syllables(text) / (len(audio) / RATE)
        if PACE[0] <= pace <= PACE[1]:
            break
    return audio, attempt, pace


def ffmpeg(args, audio=None):
    run = subprocess.run(["ffmpeg", "-v", "error", *args],
                         input=None if audio is None else audio.tobytes(),
                         capture_output=True, check=True)
    return run


def faster(audio, tempo):
    """Đọc nhanh lại mà giữ nguyên cao độ giọng."""
    out = ffmpeg(["-f", "f32le", "-ar", str(RATE), "-ac", "1", "-i", "-",
                  "-af", f"atempo={tempo:.4f}", "-f", "f32le", "-"], audio)
    return np.frombuffer(out.stdout, dtype=np.float32)


def write_wav(path, audio):
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((np.clip(audio, -1, 1) * 32767).astype("<i2").tobytes())


def loudness(path):
    run = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path),
                          "-af", "ebur128", "-f", "null", "-"],
                         capture_output=True, text=True, encoding="utf-8")
    return float(re.findall(r"I:\s+(-?[\d.]+) LUFS", run.stderr)[-1])


def main():
    voice = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_VOICE
    caps = json.load(io.open(VOICE + "/captions.json", encoding="utf-8"))
    if "textVi" not in caps[0]:
        raise SystemExit("captions.json chưa có câu tiếng Việt: chạy lại extract_captions.py")
    tts = load_tts()

    track = np.zeros(int(TOTAL * RATE) + RATE, dtype=np.float32)
    fade = np.linspace(0.0, 1.0, int(FADE_MS * RATE / 1000), dtype=np.float32)
    squeezed, overflow, retried = [], [], []

    for i, c in enumerate(caps):
        audio, attempt, pace = speak(tts, voice, c["textVi"], i)
        tempo = 1.0
        if len(audio) / RATE > c["room"]:
            tempo = min(MAX_TEMPO, len(audio) / RATE / c["room"] * 1.02)
            audio = faster(audio, tempo)
            squeezed.append((c["start"], round(tempo, 3)))
        dur = len(audio) / RATE
        if dur > c["room"]:
            overflow.append((c["start"], round(dur, 2), c["room"]))
        if attempt:
            retried.append((c["start"], attempt))
        audio = audio.copy()
        if len(audio) > 2 * len(fade):
            audio[:len(fade)] *= fade
            audio[-len(fade):] *= fade[::-1]
        at = int(c["start"] * RATE)
        track[at:at + len(audio)] += audio
        print(f'{c["start"]:6.1f}  {dur:5.2f}s / {c["room"]:5.1f}s  '
              f'{pace:4.1f} tieng/s  x{tempo:.2f}  {c["textVi"][:52]}')

    track = track[:int(TOTAL * RATE)]
    raw = Path(VOICE) / "narration_vi_raw.wav"
    final = Path(VOICE) / "narration_vi.wav"
    track *= PEAK / float(np.max(np.abs(track)))
    write_wav(raw, track)
    # Đưa về đúng độ to của bản tiếng Anh. Giọng này có vài đỉnh nhọn, nên một
    # bộ giới hạn đỉnh giữ chúng dưới trần thay vì hạ cả câu xuống.
    gain_db = TARGET_LUFS - loudness(raw)
    ffmpeg(["-y", "-i", str(raw), "-af",
            f"volume={gain_db:.2f}dB,"
            f"alimiter=limit={PEAK}:attack=5:release=50:level=0",
            str(final)])

    ffmpeg(["-y", "-i", str(final), "-c:a", "aac", "-b:a", "64k", "-ac", "1",
            "-movflags", "+faststart", OUT])

    speaking = float(np.mean(np.abs(track) > 0.001)) * 100
    print()
    print("giong            :", voice)
    print("do to            : %.1f LUFS (tieng Anh %.1f)" % (loudness(final), TARGET_LUFS))
    print("file             :", OUT, os.path.getsize(OUT), "bytes")
    print("ty le co tieng   : %.1f%% cua 8 phut" % speaking)
    print("cau phai doc lai :", len(retried), retried)
    print("cau doc nhanh lai:", len(squeezed), squeezed)
    print("cau van tran     :", len(overflow), overflow)


main()
