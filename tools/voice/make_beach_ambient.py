"""Dựng âm nền sóng biển dài 8 phút, sinh hoàn toàn bằng số.

Không dùng bản thu nào. Cùng lý do đã chọn khi dựng phần hình của cảnh biển:
bản ghi âm miễn phí luôn kèm điều kiện sử dụng mập mờ, còn thứ sinh ra từ mã
thì không vướng giấy phép của ai, và sửa lại được bao nhiêu lần cũng được.

Cấu trúc gồm ba lớp:

  - Nền sóng xa, gần như không đổi, chỉ phập phồng rất chậm.
  - Từng con sóng riêng lẻ. Mỗi con đi qua ba giai đoạn — dâng lên, vỡ, rồi
    rút — và chính chỗ vỡ mới sáng tiếng, nên hai lớp ồn tối và sáng được
    trộn theo tỉ lệ đổi dần trong suốt con sóng.
  - Một hơi gió rất nhẹ ở trên cùng.

Cường độ chung đi theo vòng ngày của phần hình: dịu lúc trước bình minh, đầy
nhất về trưa, rồi lắng lại khi trời tối.

Dùng: python tools/voice/make_beach_ambient.py
"""
import os
import sys
import wave

import numpy as np

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

VOICE = os.environ.get("EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice")
SR = 44100
TOTAL = 480.0
SEED = 20260920
TARGET_RMS = 0.0088   # đo từ nhạc nền cảnh quê, để hai bối cảnh nghe ngang nhau


def coloured(n, rng, slope, highpass_hz=0.0, lowpass_hz=0.0):
    """Ồn có phổ nghiêng theo f**(-slope), cắt được cả hai đầu.

    Phải cắt đầu trên, nếu không mọi lớp đều trôi lên vùng 6–9 kHz và cả bản
    nghe ra tiếng rít của nhiễu trắng chứ không ra tiếng sóng. Sóng thật dồn
    năng lượng quanh vài trăm Hz ở thân sóng và quanh 3 kHz ở chỗ vỡ.
    """
    w = rng.standard_normal(n)
    spec = np.fft.rfft(w)
    f = np.fft.rfftfreq(n, 1 / SR)
    shape = np.ones_like(f)
    shape[1:] = f[1:] ** (-slope)
    if highpass_hz > 0:
        # Dốc bậc hai, đủ mềm để không nghe thành tiếng rít.
        shape *= (f / highpass_hz) ** 2 / (1 + (f / highpass_hz) ** 2)
    if lowpass_hz > 0:
        shape *= 1.0 / (1 + (f / lowpass_hz) ** 2)
    shape[0] = 0.0
    out = np.fft.irfft(spec * shape, n)
    peak = np.abs(out).max()
    return out / peak if peak > 0 else out


def moving_average(x, k):
    """Trung bình trượt bằng tổng tích luỹ.

    Tích chập thẳng với một nhân dài 22 nghìn điểm trên 21 triệu mẫu là bốn
    trăm tỉ phép nhân; cách này chỉ quét mảng đúng một lượt.
    """
    pad = k // 2
    padded = np.concatenate([np.full(pad, x[0]), x, np.full(k - pad, x[-1])])
    c = np.cumsum(np.concatenate([[0.0], padded]))
    return (c[k:k + len(x)] - c[:len(x)]) / k


def wave_event(rng, length_s):
    """Một con sóng: dâng, vỡ, rút. Trả về (tín hiệu, biên độ đỉnh)."""
    n = int(length_s * SR)
    t = np.linspace(0.0, 1.0, n)

    # Dâng chậm, vỡ nhanh, rút dài — sóng thật không đối xứng.
    swell = np.clip(t / 0.42, 0, 1) ** 2.2
    decay = np.exp(-np.clip(t - 0.42, 0, None) * 4.6)
    env = swell * decay
    env /= env.max()

    # Chỗ vỡ sáng tiếng nhất, nên tỉ lệ lớp ồn sáng bám theo một đỉnh hẹp
    # quanh 0.42 chứ không bám theo cả con sóng.
    brightness = np.exp(-((t - 0.46) / 0.13) ** 2)

    # Thân sóng quanh 650 Hz, chỗ vỡ quanh 3 kHz — đo bằng trọng tâm phổ.
    low = coloured(n, rng, 0.8, highpass_hz=60.0, lowpass_hz=900.0)
    high = coloured(n, rng, 0.75, highpass_hz=700.0, lowpass_hz=4000.0)
    sig = env * (low * (1.0 - 0.45 * brightness) + high * 0.60 * brightness)
    return sig


def day_arc(t):
    """Cường độ theo vòng ngày, khớp với phần hình: dịu – đầy – lắng."""
    # Trưa rơi vào khoảng phút thứ 5 của tám phút.
    return 0.72 + 0.28 * np.sin(np.pi * np.clip(t / TOTAL, 0, 1)) ** 0.8


def build_channel(rng, offset_s):
    n = int(TOTAL * SR)
    track = np.zeros(n, dtype=np.float64)

    # --- nền sóng xa ---
    bed = np.cumsum(rng.standard_normal(n))
    bed -= moving_average(bed, SR // 2)
    bed /= np.abs(bed).max()
    t = np.arange(n) / SR
    slow = 0.78 + 0.22 * np.sin(2 * np.pi * t / 31.0 + rng.uniform(0, 6.28))
    track += 0.55 * bed * slow

    # --- từng con sóng ---
    at = offset_s + rng.uniform(0.0, 4.0)
    count = 0
    while at < TOTAL - 2.0:
        length = rng.uniform(6.5, 11.0)
        sig = wave_event(rng, length)
        start = int(at * SR)
        end = min(start + len(sig), n)
        track[start:end] += 0.85 * sig[:end - start] * float(day_arc(at))
        at += rng.uniform(7.5, 13.5)
        count += 1

    # --- hơi gió ---
    wind = coloured(n, rng, 0.8, highpass_hz=1000.0, lowpass_hz=5000.0)
    wind *= 0.55 + 0.45 * np.sin(2 * np.pi * t / 47.0 + rng.uniform(0, 6.28))
    track += 0.06 * wind

    track *= day_arc(t)
    return track, count


def main():
    rng_l = np.random.default_rng(SEED)
    rng_r = np.random.default_rng(SEED + 1)
    left, n_left = build_channel(rng_l, 0.0)
    # Sóng chạm hai tai lệch nhau một chút, nếu không sẽ nghe dính thành một
    # khối ở giữa đầu.
    right, n_right = build_channel(rng_r, 1.7)

    stereo = np.stack([left, right], axis=1)

    fade = int(4.0 * SR)
    ramp = np.linspace(0.0, 1.0, fade)[:, None]
    stereo[:fade] *= ramp
    stereo[-fade:] *= ramp[::-1]

    rms = float(np.sqrt((stereo ** 2).mean()))
    stereo *= TARGET_RMS / rms
    peak = float(np.abs(stereo).max())
    if peak > 0.9:
        stereo *= 0.9 / peak

    out = os.path.join(VOICE, "ambient_beach.wav")
    with wave.open(out, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((stereo * 32767).astype("<i2").tobytes())

    print("so con song   :", n_left, "trai /", n_right, "phai")
    print("RMS           : %.5f (dich: %.5f)"
          % (float(np.sqrt((stereo ** 2).mean())), TARGET_RMS))
    print("dinh          : %.4f" % float(np.abs(stereo).max()))
    print("file          :", out, os.path.getsize(out), "bytes")


main()
