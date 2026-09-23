import 'dart:math' as math;

import 'package:embrace_ai/core/theme.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:embrace_ai/widgets/session_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kiểm tương phản màu theo WCAG 2.2, chạy cùng bộ test thường.
///
/// Đặt ở đây chứ không để trong một báo cáo rời, vì báo cáo thì đúng đúng một
/// ngày rồi lạc hậu, còn test thì đỏ lên ngay lúc có người đổi màu. Bảng màu
/// được Material 3 sinh ra từ một màu gốc nên các giá trị dưới đây không phải
/// hằng số chép tay — chúng được hỏi thẳng từ ThemeData.
///
/// Ngưỡng: SC 1.4.3 cần 4.5:1 cho chữ thường và 3:1 cho chữ lớn (>=24px, hoặc
/// >=18.7px khi in đậm). SC 1.4.11 cần 3:1 cho thành phần giao diện và cho
/// hình khối mang thông tin.
void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
    final s = theme.colorScheme;
    final name = brightness == Brightness.dark ? 'nền tối' : 'nền sáng';

    group('Tương phản, $name', () {
      void text(String what, Color fg, Color bg, {bool large = false}) {
        test('$what — SC 1.4.3', () {
          expectRatio(fg, bg, large ? 3.0 : 4.5, what);
        });
      }

      void ui(String what, Color fg, Color bg) {
        test('$what — SC 1.4.11', () => expectRatio(fg, bg, 3.0, what));
      }

      text('Chữ thân bài trên nền trang', s.onSurface, s.surface);
      text('Chữ phụ trên nền trang', s.onSurfaceVariant, s.surface);
      text('Tiêu đề thẻ', s.onSurface, s.surfaceContainerLow);
      text('Chữ nhỏ trong thẻ', s.onSurfaceVariant, s.surfaceContainerLow);
      text('Nhãn nút chính', s.onPrimary, s.primary);
      text('Nhãn thẻ chọn đang chọn', s.onPrimaryContainer, s.primaryContainer);
      text('Nhãn thẻ chọn chưa chọn', s.onSurfaceVariant,
          s.surfaceContainerHighest);
      text('Nhãn ô bối cảnh đang chọn', s.onSurface, s.primaryContainer);
      text('Mô tả ô bối cảnh đang chọn', s.onSurfaceVariant,
          s.primaryContainer);
      text('Nhãn báo lỗi', s.error, s.surface);
      text('Chữ trong thanh thông báo', s.onInverseSurface, s.inverseSurface);
      text('Chữ trong ô nhập',
          s.onSurface, Color.alphaBlend(
              s.surfaceContainerHighest.withValues(alpha: 0.5), s.surface));

      ui('Biểu tượng nhấn mạnh', s.primary, s.surface);
      ui('Biểu tượng trong thẻ', s.primary, s.surfaceContainerLow);
      ui('Nút chính trên nền trang', s.primary, s.surface);
      ui('Dấu tích ô bối cảnh đang chọn', s.primary, s.primaryContainer);
      // Tay cầm kéo báo cho người dùng biết bảng này kéo xuống được — nó mang
      // thông tin, không phải trang trí, nên phải nhìn thấy.
      ui('Tay cầm kéo bảng hỏi', s.outline, s.surface);

      for (final mood in Mood.values) {
        final c = mood.colorOn(brightness);
        // Thanh trong biểu đồ phân bố nằm ngay trên nền rãnh, nên đó mới là
        // màu cần so, chứ không phải nền thẻ.
        ui('Thanh "${mood.label}" trên rãnh', c, s.surfaceContainerHighest);
        ui('Chấm "${mood.label}" trên thẻ', c, s.surfaceContainerLow);
      }

      test('Chữ trên vệt màu tâm trạng 22% vẫn đọc được — SC 1.4.3', () {
        for (final mood in Mood.values) {
          final tint = Color.alphaBlend(
            mood.colorOn(brightness).withValues(alpha: 0.22),
            s.surfaceContainerLow,
          );
          expectRatio(s.onSurface, tint, 4.5, 'chữ trên vệt ${mood.label}');
        }
      });
    });
  }

  group('Chữ nằm trên hình video', () {
    // Chỗ sáng nhất mà chữ có thể rơi vào, đo trên cả 8 phút của hai bối cảnh
    // bằng tools/a11y/caption_background.py. Giữ ở đây để test nói rõ nó đang
    // bảo vệ điều gì.
    const brightestVideo = 0.531;

    test('nếu không có gì phủ thì chữ trắng trượt chuẩn — đây là lý do có lớp '
        'phủ', () {
      final bare = (1.05) / (brightestVideo + 0.05);
      expect(bare, lessThan(4.5));
    });

    test('tấm nền phụ đề đủ dày cho cả trường hợp nền trắng — SC 1.4.3', () {
      expectRatio(Colors.white, _over(Colors.white, SessionScrim.captionPlate),
          4.5, 'phụ đề trên tấm nền');
    });

    test('lớp phủ hai thanh đủ dày cho chữ nhỏ — SC 1.4.3', () {
      expectRatio(Colors.white, _over(Colors.white, SessionScrim.bar), 4.5,
          'nhãn phần và đồng hồ trên lớp phủ');
    });

    test('rãnh thanh tiến độ vẫn thấy được — SC 1.4.11', () {
      final bg = _over(Colors.white, SessionScrim.bar);
      expectRatio(Color.alphaBlend(Colors.white54, bg), bg, 3.0,
          'rãnh thanh tiến độ');
    });

    test('vùng phủ đều của thanh che hết chỗ có chữ', () {
      // Chữ nằm trong nửa trên của thanh; lớp phủ phải giữ nguyên độ dày ít
      // nhất tới đó rồi mới được nhoè.
      expect(SessionScrim.barHold, greaterThanOrEqualTo(0.5));
    });
  });

  group('Màu tâm trạng', () {
    test('mỗi mức có hai sắc, không dùng chung một màu cho cả hai nền', () {
      for (final mood in Mood.values) {
        expect(mood.onLight, isNot(mood.onDark),
            reason: '${mood.label} chưa tách sắc cho nền sáng');
      }
    });

    test('năm mức phân biệt được với nhau, không chỉ dựa vào sắc độ', () {
      for (final brightness in Brightness.values) {
        final colors = Mood.values.map((m) => m.colorOn(brightness)).toList();
        for (var i = 0; i < colors.length; i++) {
          for (var j = i + 1; j < colors.length; j++) {
            expect(_ratio(colors[i], colors[j]) > 1.2 ||
                    _hueGap(colors[i], colors[j]) > 25,
                isTrue,
                reason: 'hai mức cạnh nhau nhìn ra cùng một màu');
          }
        }
      }
    });

    test('nội suy giữa hai mức không rơi ra ngoài dải màu của chúng', () {
      for (final brightness in Brightness.values) {
        final mid = Mood.colorForAverage(3.5, brightness);
        final a = Mood.neutral.colorOn(brightness);
        final b = Mood.good.colorOn(brightness);
        expect(_lum(mid), greaterThanOrEqualTo(math.min(_lum(a), _lum(b)) - 0.01));
        expect(_lum(mid), lessThanOrEqualTo(math.max(_lum(a), _lum(b)) + 0.01));
      }
    });
  });
}

/// Màu nhìn thấy khi phủ một lớp đen [alpha] lên nền [bg].
Color _over(Color bg, double alpha) =>
    Color.alphaBlend(Colors.black.withValues(alpha: alpha), bg);

void expectRatio(Color fg, Color bg, double need, String what) {
  final got = _ratio(fg, bg);
  expect(got, greaterThanOrEqualTo(need),
      reason: '$what: ${got.toStringAsFixed(2)}:1, cần $need:1 '
          '(${_hex(fg)} trên ${_hex(bg)})');
}

double _channel(double v) =>
    v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double _lum(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _ratio(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double _hueGap(Color a, Color b) {
  final ha = HSLColor.fromColor(a).hue, hb = HSLColor.fromColor(b).hue;
  final d = (ha - hb).abs();
  return math.min(d, 360 - d);
}

String _hex(Color c) {
  int ch(double v) => (v * 255).round().clamp(0, 255);
  return '#${ch(c.r).toRadixString(16).padLeft(2, '0')}'
      '${ch(c.g).toRadixString(16).padLeft(2, '0')}'
      '${ch(c.b).toRadixString(16).padLeft(2, '0')}';
}
