import 'dart:async';
import 'dart:io';

import 'package:embrace_ai/core/theme.dart';
import 'package:embrace_ai/state/journal_store.dart';
import 'package:embrace_ai/state/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Bộ đồ nghề để chụp màn hình app mà không cần máy thật hay trình duyệt.
///
/// Môi trường `flutter test` mặc định vẽ chữ bằng font giả (toàn ô vuông),
/// nên phải nạp font thật của Windows vào — và phải có cả font emoji, vì các
/// mức tâm trạng dùng emoji.
class ScreenshotHarness {
  const ScreenshotHarness._();

  /// Khổ điện thoại phổ thông, mật độ 3x.
  static const phone = Size(390, 844);
  static const pixelRatio = 3.0;

  static Future<ByteData> _fontBytes(String path) async {
    final data = await File(path).readAsBytes();
    return ByteData.view(Uint8List.fromList(data).buffer);
  }

  /// Trên Windows, typography mặc định của Flutter dùng họ "Segoe UI", trên
  /// Android là "Roboto". Đăng ký cùng một file font dưới mọi tên có thể gặp
  /// thì chữ nào cũng có font thật, không còn ô vuông.
  static const _uiFamilies = [
    'Roboto',
    'Segoe UI',
    'SF Pro Text',
    '.SF UI Text',
  ];

  static Future<void> loadFonts() async {
    const segoe = 'C:/Windows/Fonts/segoeui.ttf';
    for (final family in _uiFamilies) {
      final loader = FontLoader(family)..addFont(_fontBytes(segoe));
      await loader.load();
    }
    final emoji = FontLoader('Segoe UI Emoji')
      ..addFont(_fontBytes('C:/Windows/Fonts/seguiemj.ttf'));
    await emoji.load();
    // Thiếu font này thì mọi icon đều ra ô vuông.
    final icons = FontLoader('MaterialIcons')
      ..addFont(_fontBytes(
          'C:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf'));
    await icons.load();
  }

  /// Nạp sẵn ảnh vào cache để widget test vẽ được ngay (test không tự chờ
  /// giải mã ảnh bất đồng bộ).
  static Future<void> preload(
    WidgetTester tester,
    ImageProvider provider,
  ) async {
    await tester.runAsync(() async {
      final done = Completer<void>();
      final stream = provider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, _) {
          stream.removeListener(listener);
          if (!done.isCompleted) done.complete();
        },
        onError: (e, _) {
          stream.removeListener(listener);
          if (!done.isCompleted) done.completeError(e);
        },
      );
      stream.addListener(listener);
      await done.future;
    });
  }

  /// Dựng cây widget giống app thật, cỡ điện thoại, áp đúng cỡ chữ đã chọn.
  static Widget wrap(
    Widget child, {
    SettingsStore? settings,
    JournalStore? journal,
    Brightness brightness = Brightness.light,
  }) {
    final store = settings ?? SettingsStore();
    final base = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        if (journal != null) ChangeNotifierProvider.value(value: journal),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: base.copyWith(
          textTheme: base.textTheme
              .apply(fontFamilyFallback: const ['Segoe UI', 'Segoe UI Emoji']),
          // Style mặc định của Chip trỏ tới một họ font không đăng ký được
          // trong môi trường test nên nhãn ra ô vuông. Chỉ định thẳng ở đây;
          // trên máy thật app vẫn dùng font hệ thống như bình thường.
          chipTheme: base.chipTheme.copyWith(
            labelStyle: base.chipTheme.labelStyle?.copyWith(
              fontFamily: 'Segoe UI',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            secondaryLabelStyle: base.chipTheme.secondaryLabelStyle?.copyWith(
              fontFamily: 'Segoe UI',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, inner) {
          final scale = context.watch<SettingsStore>().textScale;
          return MediaQuery.withClampedTextScaling(
            minScaleFactor: scale,
            maxScaleFactor: scale,
            child: inner ?? const SizedBox.shrink(),
          );
        },
        home: child,
      ),
    );
  }

  static void sizePhone(WidgetTester tester) {
    tester.view.physicalSize =
        Size(phone.width * pixelRatio, phone.height * pixelRatio);
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);
  }
}
