"""Đo tương phản màu theo WCAG 2.2 trên đúng bảng màu app đang chạy.

Bảng màu do Material 3 sinh ra từ một màu gốc, nên nó được lấy từ Flutter
(`test/support/dump_scheme.dart`) chứ không chép tay. Các cặp màu liệt kê ở
đây là những cặp thật sự xuất hiện trên màn hình, không phải mọi tổ hợp có
thể có — một cặp không ai nhìn thấy thì đạt hay trượt đều vô nghĩa.

Ngưỡng: SC 1.4.3 cần 4.5:1 cho chữ thường, 3:1 cho chữ lớn (>=24px, hoặc
>=18.7px khi in đậm). SC 1.4.11 cần 3:1 cho thành phần giao diện.
"""
import io
import json
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCHEME = "build/scheme.json"


def srgb_to_linear(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def luminance(hex_color):
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return (0.2126 * srgb_to_linear(r)
            + 0.7152 * srgb_to_linear(g)
            + 0.0722 * srgb_to_linear(b))


def ratio(fg, bg):
    a, b = luminance(fg), luminance(bg)
    hi, lo = max(a, b), min(a, b)
    return (hi + 0.05) / (lo + 0.05)


def blend(fg, bg, alpha):
    """Màu nằm trên nền với độ mờ alpha — mắt nhìn thấy màu đã trộn."""
    f = fg.lstrip("#")
    b = bg.lstrip("#")
    out = []
    for i in (0, 2, 4):
        fv, bv = int(f[i:i + 2], 16), int(b[i:i + 2], 16)
        out.append(round(fv * alpha + bv * (1 - alpha)))
    return "#" + "".join(f"{v:02x}" for v in out)


# (mô tả, khoá màu chữ, khoá màu nền, cỡ px, đậm, loại)
PAIRS = [
    ("Chữ thân bài trên nền trang", "onSurface", "surface", 16, False, "text"),
    ("Tiêu đề lớn trang mở đầu", "onSurface", "surface", 28, False, "text"),
    ("Chữ phụ trên nền trang", "onSurfaceVariant", "surface", 16, False, "text"),
    ("Chữ nhỏ trên nền trang", "onSurfaceVariant", "surface", 12, False, "text"),
    ("Tiêu đề thẻ", "onSurface", "surfaceContainerLow", 14, True, "text"),
    ("Chữ nhỏ trong thẻ", "onSurfaceVariant", "surfaceContainerLow", 12,
     False, "text"),
    ("Nhãn nút chính", "onPrimary", "primary", 16, True, "text"),
    ("Nhãn thẻ chọn đang chọn", "onPrimaryContainer", "primaryContainer", 14,
     False, "text"),
    ("Nhãn thẻ chọn chưa chọn", "onSurfaceVariant", "surfaceContainerHighest",
     14, False, "text"),
    ("Nhãn ô bối cảnh đang chọn", "onSurface", "primaryContainer", 14, True,
     "text"),
    ("Mô tả ô bối cảnh đang chọn", "onSurfaceVariant", "primaryContainer", 12,
     False, "text"),
    ("Chữ trong ô nhập", "onSurface", "_inputFill", 16, False, "text"),
    ("Nhãn báo lỗi", "error", "surface", 12, False, "text"),
    ("Chữ trong thanh thông báo", "onInverseSurface", "inverseSurface", 14,
     False, "text"),
    ("Biểu tượng nhấn mạnh", "primary", "surface", 0, False, "ui"),
    ("Biểu tượng trong thẻ", "primary", "surfaceContainerLow", 0, False, "ui"),
    ("Nút chính so với nền trang", "primary", "surface", 0, False, "ui"),
    ("Dấu tích ô bối cảnh đang chọn", "primary", "primaryContainer", 0, False,
     "ui"),
    ("Đường kẻ phân cách", "outlineVariant", "surface", 0, False, "ui"),
    ("Viền ngoài", "outline", "surface", 0, False, "ui"),
]


def threshold(size_px, bold, kind):
    if kind == "ui":
        return 3.0, "SC 1.4.11"
    large = size_px >= 24 or (bold and size_px >= 18.7)
    return (3.0, "SC 1.4.3 (chữ lớn)") if large else (4.5, "SC 1.4.3")


def audit(scheme, name):
    colors = dict(scheme)
    # Ô nhập dùng nền mờ 50%, nên màu mắt thấy là màu đã trộn.
    colors["_inputFill"] = blend(colors["surfaceContainerHighest"],
                                 colors["surface"], 0.5)
    rows = []
    for desc, fg, bg, size, bold, kind in PAIRS:
        need, sc = threshold(size, bold, kind)
        got = ratio(colors[fg], colors[bg])
        rows.append({
            "desc": desc, "fg": fg, "bg": bg,
            "fg_hex": colors[fg], "bg_hex": colors[bg],
            "size": size, "bold": bold, "kind": kind,
            "need": need, "got": round(got, 2), "sc": sc,
            "pass": got >= need,
        })
    failed = [r for r in rows if not r["pass"]]
    print(f"=== {name} ===")
    for r in rows:
        mark = "dat " if r["pass"] else "TRUOT"
        print(f'  {mark} {r["got"]:6.2f}:1 (can {r["need"]}) {r["sc"]:22s} '
              f'{r["desc"]}')
    print(f'  -> {len(rows) - len(failed)}/{len(rows)} dat')
    print()
    return rows


def main():
    scheme = json.load(io.open(SCHEME, encoding="utf-8"))
    result = {name: audit(scheme[name], name) for name in ("light", "dark")}
    json.dump(result, io.open("build/contrast.json", "w", encoding="utf-8"),
              ensure_ascii=False, indent=1)
    bad = [r for rows in result.values() for r in rows if not r["pass"]]
    print("tong so cap truot:", len(bad))
    for r in bad:
        print("   ", r["desc"], r["fg_hex"], "tren", r["bg_hex"],
              f'{r["got"]}:1 < {r["need"]}')


if __name__ == "__main__":
    main()
