import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'state/settings_store.dart';

class EmbraceApp extends StatelessWidget {
  const EmbraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    return MaterialApp(
      title: 'EmbraceAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightFor(reduceMotion: settings.reduceMotion),
      darkTheme: AppTheme.darkFor(reduceMotion: settings.reduceMotion),
      themeAnimationDuration: settings.reduceMotion
          ? Duration.zero
          : kThemeAnimationDuration,
      themeMode: ThemeMode.system,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
      home: const HomeScreen(),
    );
  }
}
