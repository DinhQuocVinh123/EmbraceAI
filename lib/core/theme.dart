import 'package:flutter/material.dart';

/// Bảng màu và typography dùng chung cho toàn app.
class AppTheme {
  const AppTheme._();

  /// Màu chủ đạo: xanh ngọc dịu, tạo cảm giác bình tĩnh.
  static const seed = Color(0xFF4DB6AC);

  static ThemeData get light => lightFor();
  static ThemeData get dark => darkFor();

  static ThemeData lightFor({bool reduceMotion = false}) =>
      _build(Brightness.light, reduceMotion: reduceMotion);
  static ThemeData darkFor({bool reduceMotion = false}) =>
      _build(Brightness.dark, reduceMotion: reduceMotion);

  static ThemeData _build(Brightness brightness, {required bool reduceMotion}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
        // Không có viền thì phải có nền, nếu không thẻ trông như chữ trần
        // và người dùng không biết là bấm được.
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimaryContainer),
        checkmarkColor: scheme.onPrimaryContainer,
      ),
    );
    if (!reduceMotion) return theme;
    return theme.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NoMotionPageTransitionsBuilder(),
          TargetPlatform.iOS: _NoMotionPageTransitionsBuilder(),
          TargetPlatform.macOS: _NoMotionPageTransitionsBuilder(),
          TargetPlatform.windows: _NoMotionPageTransitionsBuilder(),
          TargetPlatform.linux: _NoMotionPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _NoMotionPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class _NoMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoMotionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// Khoảng cách chuẩn, tránh rải magic number khắp nơi.
class Gap {
  const Gap._();
  static const xs = SizedBox(height: 4, width: 4);
  static const s = SizedBox(height: 8, width: 8);
  static const m = SizedBox(height: 16, width: 16);
  static const l = SizedBox(height: 24, width: 24);
  static const xl = SizedBox(height: 32, width: 32);
}
