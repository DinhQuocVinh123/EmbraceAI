"""Dựng một dải lời đọc dài 8 phút, khớp đúng mốc phụ đề của kịch bản.

Mỗi câu được đọc riêng rồi đặt vào đúng giây nó xuất hiện trên màn hình, thay
vì đọc liền một mạch rồi hy vọng nó trôi đúng chỗ. Câu nào đọc dài hơn khoảng
trống tới câu kế tiếp thì đọc nhanh lại vừa đủ, và chỉ câu đó.

Dùng: python synth_narration.py <ten-giong> [thu-muc-ra]
"""
import io
import json
import os
import sys
import wave

import numpy as np

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Phần nặng — bản video câm gốc, mô hình giọng, dải lời đọc — để ngoài
# repo app: build/ bị flutter clean xoá, còn assets/ thì bị đóng vào APK.
VOICE = os.environ.get("EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice")

MODELS = VOICE + "/piper_models"
TOTAL = 480.0
BASE_LENGTH = 1.22   # chậm hơn mặc định — đây là bài thiền, không phải bản tin
MIN_LENGTH = 0.95    # dưới mức này giọng bắt đầu nghe hối
FADE_MS = 25         # chống tiếng tách ở đầu và cuối mỗi câu


def synth(voice, text, length_scale):
    from piper import SynthesisConfig
    cfg = SynthesisConfig(length_scale=length_scale, noise_scale=0.667,
                          noise_w_scale=0.8)
    chunks = [c.audio_float_array for c in voice.synthesize(text, syn_config=cfg)]
    return np.concatenate(chunks) if chunks else np.zeros(0, dtype=np.float32)


def fit(voice, text, room):
    """Đọc câu này sao cho lọt vào khoảng trống, ưu tiên giữ nhịp chậm."""
    length = BASE_LENGTH
    audio = synth(voice, text, length)
    rate = voice.config.sample_rate
    if len(audio) / rate <= room:
        return audio, length, False
    # Rút vừa đủ, không rút quá tay.
    needed = room * rate / len(audio)
    length = max(MIN_LENGTH, BASE_LENGTH * needed * 0.98)
    audio = synth(voice, text, length)
    return audio, length, len(audio) / rate > room


def main():
    model = sys.argv[1] if len(sys.argv) > 1 else "en_GB-jenny_dioco-medium"
    out_dir = sys.argv[2] if len(sys.argv) > 2 else VOICE
    from piper import PiperVoice

    caps = json.load(io.open(VOICE + "/captions.json", encoding="utf-8"))
    voice = PiperVoice.load(os.path.join(MODELS, model + ".onnx"))
    rate = voice.config.sample_rate

    track = np.zeros(int(TOTAL * rate) + rate, dtype=np.float32)
    fade = np.linspace(0.0, 1.0, int(FADE_MS * rate / 1000), dtype=np.float32)
    squeezed = []
    overflow = []

    for c in caps:
        audio, length, spilled = fit(voice, c["text"], c["room"])
        audio = audio.astype(np.float32).copy()
        if len(audio) > 2 * len(fade):
            audio[:len(fade)] *= fade
            audio[-len(fade):] *= fade[::-1]
        at = int(c["start"] * rate)
        track[at:at + len(audio)] += audio
        dur = len(audio) / rate
        if length < BASE_LENGTH - 1e-6:
            squeezed.append((c["start"], round(length, 3), round(dur, 2),
                             c["room"]))
        if spilled:
            overflow.append((c["start"], round(dur, 2), c["room"]))
        print(f'{c["start"]:6.1f}  {dur:5.2f}s / {c["room"]:5.1f}s  '
              f'ls={length:.2f}  {c["text"][:52]}')

    track = track[:int(TOTAL * rate)]
    peak = float(np.max(np.abs(track)))
    if peak > 0:
        track *= 0.89 / peak

    out = os.path.join(out_dir, "narration.wav")
    with wave.open(out, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes((track * 32767).astype("<i2").tobytes())

    speaking = float(np.mean(np.abs(track) > 0.001)) * 100
    print()
    print("giong          :", model)
    print("tan so          :", rate, "Hz")
    print("file            :", out, os.path.getsize(out), "bytes")
    print("ty le co tieng  : %.1f%% cua 8 phut" % speaking)
    print("cau phai doc nhanh lai:", len(squeezed), squeezed)
    print("cau van tran    :", len(overflow), overflow)


main()
