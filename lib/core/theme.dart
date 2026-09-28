import 'package:flutter/material.dart';

/// Bảng màu và typography dùng chung cho toàn app.
///
/// Phong cách theo shadcn/ui: nền trung tính (dải xám zinc), thẻ nền phẳng có
/// viền mảnh thay cho mảng tô màu, bo góc nhỏ, và chỉ một màu nhấn. Màu nhấn
/// là xanh ngọc đậm — giữ cảm giác bình tĩnh của app, nhưng dùng tiết kiệm:
/// nút chính, trạng thái đang chọn, và biểu tượng.
///
/// Bảng màu được viết tay thay vì sinh từ một màu gốc, vì bảng sinh tự động
/// ám màu nhấn vào mọi nền. Mọi cặp chữ/nền ở đây được `contrast_test.dart`
/// kiểm theo WCAG 2.2, nên đổi màu nào thì chạy lại test đó.
class AppTheme {
  const AppTheme._();

  /// Màu nhấn: xanh ngọc đậm (teal-700), tạo cảm giác bình tĩnh.
  static const seed = Color(0xFF0F766E);

  static ThemeData get light => lightFor();
  static ThemeData get dark => darkFor();

  static ThemeData lightFor({bool reduceMotion = false}) =>
      _build(_lightScheme, reduceMotion: reduceMotion);
  static ThemeData darkFor({bool reduceMotion = false}) =>
      _build(_darkScheme, reduceMotion: reduceMotion);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0F766E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCCFBF1),
    onPrimaryContainer: Color(0xFF134E4A),
    secondary: Color(0xFF52525B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF4F4F5),
    onSecondaryContainer: Color(0xFF18181B),
    tertiary: Color(0xFF0369A1),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE0F2FE),
    onTertiaryContainer: Color(0xFF0C4A6E),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF09090B),
    onSurfaceVariant: Color(0xFF52525B),
    surfaceDim: Color(0xFFF4F4F5),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAFAFA),
    surfaceContainer: Color(0xFFF4F4F5),
    surfaceContainerHigh: Color(0xFFF4F4F5),
    surfaceContainerHighest: Color(0xFFF4F4F5),
    // Viền của ô nhập và tay cầm kéo phải đạt 3:1 (SC 1.4.11), nên outline
    // đậm hơn viền thẻ; outlineVariant là đường kẻ trang trí.
    outline: Color(0xFF71717A),
    outlineVariant: Color(0xFFE4E4E7),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF18181B),
    onInverseSurface: Color(0xFFFAFAFA),
    inversePrimary: Color(0xFF5EEAD4),
    surfaceTint: Color(0x00000000),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF2DD4BF),
    onPrimary: Color(0xFF042F2E),
    primaryContainer: Color(0xFF0F2E2B),
    onPrimaryContainer: Color(0xFFCCFBF1),
    secondary: Color(0xFFA1A1AA),
    onSecondary: Color(0xFF18181B),
    secondaryContainer: Color(0xFF27272A),
    onSecondaryContainer: Color(0xFFFAFAFA),
    tertiary: Color(0xFF7DD3FC),
    onTertiary: Color(0xFF082F49),
    tertiaryContainer: Color(0xFF0C4A6E),
    onTertiaryContainer: Color(0xFFE0F2FE),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF09090B),
    onSurface: Color(0xFFFAFAFA),
    onSurfaceVariant: Color(0xFFA1A1AA),
    surfaceDim: Color(0xFF09090B),
    surfaceBright: Color(0xFF27272A),
    surfaceContainerLowest: Color(0xFF09090B),
    surfaceContainerLow: Color(0xFF111113),
    surfaceContainer: Color(0xFF18181B),
    surfaceContainerHigh: Color(0xFF27272A),
    surfaceContainerHighest: Color(0xFF27272A),
    outline: Color(0xFF71717A),
    outlineVariant: Color(0xFF27272A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFAFAFA),
    onInverseSurface: Color(0xFF18181B),
    inversePrimary: Color(0xFF0F766E),
    surfaceTint: Color(0x00000000),
  );

  static ThemeData _build(ColorScheme scheme, {required bool reduceMotion}) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
    );
    final text = _textTheme(base.textTheme, scheme);
    final border = BorderSide(color: scheme.outlineVariant);
    final small = RoundedRectangleBorder(borderRadius: AppRadius.md);

    final theme = base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: border),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg, side: border),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: small,
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: small,
          elevation: 0,
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          side: border,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: small,
          foregroundColor: scheme.onSurface,
          side: border,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: small,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: small),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: small,
          side: border,
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        // Viền mảnh cho thẻ chưa chọn để người dùng biết là bấm được; thẻ đã
        // chọn đổi sang nền nhấn nhạt.
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(color: scheme.primary)
              : border,
        ),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        secondaryLabelStyle: text.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        checkmarkColor: scheme.onPrimaryContainer,
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outline,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        iconColor: scheme.onSurfaceVariant,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg, side: border),
        titleTextStyle: text.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          side: border,
        ),
        dragHandleColor: scheme.outline,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md, side: border),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.md, side: border),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: AppRadius.sm,
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.secondaryContainer,
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: text.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        dataTextStyle: text.bodyMedium,
        dividerThickness: 1,
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

  /// Tiêu đề đậm vừa và khít chữ hơn một chút, thân bài giữ nguyên cỡ để
  /// người lớn tuổi vẫn đọc thoải mái.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? heading(TextStyle? s, double spacing) => s?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: spacing,
      color: scheme.onSurface,
    );
    return base
        .copyWith(
          displaySmall: heading(base.displaySmall, -0.8),
          headlineLarge: heading(base.headlineLarge, -0.6),
          headlineMedium: heading(base.headlineMedium, -0.5),
          headlineSmall: heading(base.headlineSmall, -0.4),
          titleLarge: heading(base.titleLarge, -0.2)?.copyWith(fontSize: 20),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}

/// Bo góc chuẩn. shadcn dùng một thang nhỏ; giữ đúng ba bậc để các màn hình
/// không tự chế độ bo riêng.
class AppRadius {
  const AppRadius._();
  static const sm = BorderRadius.all(Radius.circular(6));
  static const md = BorderRadius.all(Radius.circular(8));
  static const lg = BorderRadius.all(Radius.circular(12));
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
