import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_surface.dart';
import 'core/theme.dart';
import 'l10n/l10n.dart';
import 'screens/home_screen.dart';
import 'state/settings_store.dart';

class EmbraceApp extends StatelessWidget {
  const EmbraceApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    return MaterialApp(
      title: AppSurface.current == AppSurface.staff
          ? 'EmbraceAI Staff Portal'
          : 'EmbraceAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightFor(reduceMotion: settings.reduceMotion),
      darkTheme: AppTheme.darkFor(reduceMotion: settings.reduceMotion),
      themeAnimationDuration: settings.reduceMotion
          ? Duration.zero
          : kThemeAnimationDuration,
      themeMode: ThemeMode.system,
      // App người tham gia có tiếng Anh và tiếng Việt, mặc định theo điện thoại
      // (locale null); cổng nhân viên luôn bằng tiếng Anh.
      locale: AppSurface.current == AppSurface.staff
          ? const Locale('en')
          : settings.language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Cỡ chữ người dùng chọn áp cho TOÀN app, không riêng màn hình thiền —
      // góp ý "text sizes should be bigger" là về cả giao diện.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final systemScale = media.textScaler.scale(1);
        final effectiveScale = math.max(systemScale, settings.textScale);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(effectiveScale),
            disableAnimations: media.disableAnimations || settings.reduceMotion,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: home ?? const HomeScreen(),
    );
  }
}
