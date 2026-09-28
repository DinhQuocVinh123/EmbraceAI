import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Luật của design system, kiểm như một linter.
///
/// Cùng tinh thần với `@shadcn/lint` (vốn chỉ chạy cho React/Tailwind): màn
/// hình không tự chế màu hay độ bo góc, mà lấy từ `lib/core/theme.dart`. Khi
/// một luật đỏ, thông báo nói rõ phải sửa thành gì — để người hay agent đọc
/// là sửa được ngay, không phải đoán.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
  String rel(File f) => f.path.replaceAll(r'\', '/');

  test('màu viết tay chỉ nằm trong theme và các bảng màu dữ liệu', () {
    // mood.dart và session_scene.dart là màu mang nghĩa dữ liệu (mức tâm
    // trạng, màu mẫu của bối cảnh), không phải màu giao diện.
    const allowed = {
      'lib/core/theme.dart',
      'lib/models/mood.dart',
      'lib/models/session_scene.dart',
    };
    final hex = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
    final offenders = <String>[];
    for (final f in files) {
      if (allowed.contains(rel(f))) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (hex.hasMatch(lines[i])) offenders.add('${rel(f)}:${i + 1}');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Không viết mã màu trực tiếp. Lấy từ Theme.of(context).colorScheme '
          '(primary, onSurface, onSurfaceVariant, outlineVariant, ...). Cần '
          'màu mới thì thêm vào ColorScheme trong lib/core/theme.dart rồi chạy '
          'test/contrast_test.dart.\n${offenders.join('\n')}',
    );
  });

  test('bo góc lấy từ AppRadius, không tự đặt số', () {
    // Nợ cũ: các màn hình phiên thiền và phụ lục chưa được làm lại giao diện.
    // Khi làm lại file nào thì gỡ nó khỏi danh sách này.
    const legacy = {
      'lib/screens/final_assessment_screen.dart',
      'lib/screens/session_screen.dart',
      'lib/widgets/mood_distribution.dart',
      'lib/widgets/mood_picker.dart',
      'lib/widgets/session_chrome.dart',
      'lib/widgets/session_prompts.dart',
    };
    final offenders = <String>[];
    for (final f in files) {
      if (legacy.contains(rel(f)) || rel(f) == 'lib/core/theme.dart') continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('BorderRadius.circular(')) {
          offenders.add('${rel(f)}:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Dùng AppRadius.sm (6), AppRadius.md (8, nút/ô nhập/chip) hoặc '
          'AppRadius.lg (12, thẻ/hộp thoại) thay cho BorderRadius.circular(n).'
          '\n${offenders.join('\n')}',
    );
  });
}
