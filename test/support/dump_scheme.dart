import 'dart:convert';
import 'dart:io';

import 'package:embrace_ai/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ghi bảng màu Flutter sinh ra ra file, để công cụ kiểm tương phản đọc.
///
/// Bảng màu được sinh từ một màu gốc bằng thuật toán của Material 3, nên giá
/// trị thật chỉ biết được khi chạy Flutter. Chép tay sang chỗ khác là tự chuốc
/// lấy rủi ro báo cáo một đằng, app một nẻo.
void main() {
  test('ghi bang mau ra build/scheme.json', () {
    final out = <String, Object>{};
    for (final entry in {
      'light': AppTheme.light,
      'dark': AppTheme.dark,
    }.entries) {
      final s = entry.value.colorScheme;
      out[entry.key] = <String, String>{
        'primary': _hex(s.primary),
        'onPrimary': _hex(s.onPrimary),
        'primaryContainer': _hex(s.primaryContainer),
        'onPrimaryContainer': _hex(s.onPrimaryContainer),
        'secondary': _hex(s.secondary),
        'onSecondary': _hex(s.onSecondary),
        'error': _hex(s.error),
        'onError': _hex(s.onError),
        'surface': _hex(s.surface),
        'onSurface': _hex(s.onSurface),
        'onSurfaceVariant': _hex(s.onSurfaceVariant),
        'surfaceContainerLow': _hex(s.surfaceContainerLow),
        'surfaceContainerHighest': _hex(s.surfaceContainerHighest),
        'outline': _hex(s.outline),
        'outlineVariant': _hex(s.outlineVariant),
        'inverseSurface': _hex(s.inverseSurface),
        'onInverseSurface': _hex(s.onInverseSurface),
      };
    }
    File('build/scheme.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent(' ').convert(out));
  });
}

String _hex(Color c) {
  int ch(double v) => (v * 255).round().clamp(0, 255);
  return '#${ch(c.r).toRadixString(16).padLeft(2, '0')}'
      '${ch(c.g).toRadixString(16).padLeft(2, '0')}'
      '${ch(c.b).toRadixString(16).padLeft(2, '0')}';
}
