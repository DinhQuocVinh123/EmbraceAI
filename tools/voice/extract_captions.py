"""Rút toàn bộ phụ đề kèm mốc thời gian từ session_script.dart.

Kịch bản là nguồn sự thật duy nhất: lời đọc phải khớp với chữ hiện trên màn
hình, nên nó được đọc thẳng từ file Dart chứ không chép tay sang chỗ khác.
"""
import io
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Phần nặng — bản video câm gốc, mô hình giọng, dải lời đọc — để ngoài
# repo app: build/ bị flutter clean xoá, còn assets/ thì bị đóng vào APK.
VOICE = os.environ.get("EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice")

BS = chr(92)  # dấu gạch chéo ngược
ESCAPES = {"n": chr(10), "t": chr(9), "'": "'", '"': '"', BS: BS}
GUARD = 0.4      # khoảng thở giữa hai câu, giây
TOTAL = 480.0    # độ dài video


def parse_literals(seg):
    """Nối các chuỗi Dart liền kề trong một đoạn."""
    out = []
    i = 0
    while i < len(seg):
        ch = seg[i]
        if ch in "'\"":
            quote = ch
            i += 1
            buf = []
            while i < len(seg):
                c = seg[i]
                if c == BS:
                    nxt = seg[i + 1]
                    buf.append(ESCAPES.get(nxt, nxt))
                    i += 2
                    continue
                if c == quote:
                    i += 1
                    break
                buf.append(c)
                i += 1
            out.append("".join(buf))
        else:
            i += 1
    return "".join(out)


def main():
    src = io.open("lib/data/session_script.dart", encoding="utf-8").read()
    caps = []
    for m in re.finditer(r"Caption\(", src):
        i = m.end()
        start = i
        depth = 1
        while depth:
            if src[i] == "(":
                depth += 1
            elif src[i] == ")":
                depth -= 1
            i += 1
        body = src[start:i - 1]
        tm = re.match(r"\s*_ms\(([\d.]+)\)\s*,\s*_ms\(([\d.]+)\)\s*,", body)
        caps.append({
            "start": float(tm.group(1)),
            "end": float(tm.group(2)),
            "text": parse_literals(body[tm.end():]),
        })

    caps.sort(key=lambda c: c["start"])
    for i, c in enumerate(caps):
        nxt = caps[i + 1]["start"] if i + 1 < len(caps) else TOTAL
        # Chỗ thật sự có để đọc là tới lúc câu sau bắt đầu, không phải tới lúc
        # câu này biến mất — phụ đề tắt sớm hơn là chuyện bình thường.
        c["room"] = round(nxt - c["start"] - GUARD, 3)
        c["window"] = round(c["end"] - c["start"], 3)

    json.dump(caps, io.open(VOICE + "/captions.json", "w", encoding="utf-8"),
              ensure_ascii=False, indent=1)

    print("so cau:", len(caps))
    tight = [c for c in caps if c["room"] < 4.0]
    print("cau co it hon 4s de doc:", len(tight))
    for c in caps:
        print(f'{c["start"]:6.1f} win={c["window"]:5.1f} room={c["room"]:6.1f}  '
              f'{c["text"][:66]}')


main()
