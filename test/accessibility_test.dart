import 'dart:ui' show SemanticsAction;

import 'package:embrace_ai/app.dart';
import 'package:embrace_ai/core/motion.dart';
import 'package:embrace_ai/models/breathing_cue.dart';
import 'package:embrace_ai/screens/welcome_screen.dart';
import 'package:embrace_ai/state/journal_store.dart';
import 'package:embrace_ai/state/settings_store.dart';
import 'package:embrace_ai/widgets/session_chrome.dart';
import 'package:embrace_ai/widgets/mood_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('system text scale is never reduced by the app setting', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final settings = SettingsStore();
    final journal = JournalStore(FakeRepository());
    await journal.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: journal),
        ],
        child: const EmbraceApp(),
      ),
    );
    await tester.pumpAndSettle();

    BuildContext welcomeContext = tester.element(find.byType(WelcomeScreen));
    expect(MediaQuery.textScalerOf(welcomeContext).scale(1), 1.8);
    expect(
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .animationDuration,
      AppMotion.standard,
    );

    await settings.setTextScale(2);
    await tester.pumpAndSettle();
    welcomeContext = tester.element(find.byType(WelcomeScreen));
    expect(MediaQuery.textScalerOf(welcomeContext).scale(1), 2);

    await settings.setReduceMotion(true);
    await tester.pumpAndSettle();
    welcomeContext = tester.element(find.byType(WelcomeScreen));
    expect(MediaQuery.of(welcomeContext).disableAnimations, isTrue);
    expect(
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .animationDuration,
      Duration.zero,
    );
  });

  testWidgets('Android reduce motion disables the shared motion policy', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final settings = SettingsStore();
    final journal = JournalStore(FakeRepository());
    await journal.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: journal),
        ],
        child: const EmbraceApp(),
      ),
    );
    await tester.pumpAndSettle();

    final welcomeContext = tester.element(find.byType(WelcomeScreen));
    expect(settings.reduceMotion, isFalse);
    expect(MediaQuery.disableAnimationsOf(welcomeContext), isTrue);
    expect(
      AppMotion.duration(welcomeContext, AppMotion.standard),
      Duration.zero,
    );
    expect(
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .animationDuration,
      Duration.zero,
    );
    expect(
      tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .map((widget) => widget.duration),
      everyElement(Duration.zero),
    );
  });

  testWidgets('motion switcher changes duration with accessibility setting', (
    tester,
  ) async {
    for (final reduced in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const MotionSwitcher(
              child: SizedBox(key: ValueKey('content')),
            ),
          ),
        ),
      );

      final switcher = tester.widget<AnimatedSwitcher>(
        find.descendant(
          of: find.byType(MotionSwitcher),
          matching: find.byType(AnimatedSwitcher),
        ),
      );
      expect(switcher.duration, reduced ? Duration.zero : AppMotion.standard);
    }
  });

  testWidgets('session exposes part, caption and elapsed time semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionStage(
            videoSurface: Semantics(
              label: 'Decorative video surface',
              child: const ColoredBox(color: Colors.black),
            ),
            aspectRatio: 16 / 9,
            beatNumber: 2,
            beatTitle: 'Comfortable breathing',
            totalBeats: 4,
            position: const Duration(minutes: 1, seconds: 5),
            total: const Duration(minutes: 3, seconds: 20),
            isPlaying: true,
            caption: 'Let your breathing stay natural.',
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Part 2 of 4. Comfortable breathing'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Caption: Let your breathing stay natural.'),
      findsOneWidget,
    );
    final progress = tester.getSemantics(
      find.bySemanticsLabel('Session progress'),
    );
    expect(progress.value, '1 minute 5 seconds of 3 minutes 20 seconds');
    expect(find.bySemanticsLabel('Decorative video surface'), findsNothing);
    semantics.dispose();
  });

  testWidgets('reduce motion freezes the breathing ring but keeps its cue', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BreathingGuide(
            cue: BreathingCue(
              phase: BreathingPhase.inhale,
              progress: 0.5,
            ),
            reduceMotion: true,
          ),
        ),
      ),
    );

    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('breathing-guide-ring')),
    );
    expect(transform.transform.getMaxScaleOnAxis(), 1);
    expect(
      find.bySemanticsLabel('Breathing guide: Breathe in'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('caption rail keeps the video fixed at ${scale}x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Widget stage(String? caption) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SessionStage(
              videoSurface: const ColoredBox(
                key: ValueKey('video-surface'),
                color: Colors.black,
              ),
              aspectRatio: 16 / 9,
              beatNumber: 1,
              beatTitle: 'Arrival and orientation',
              totalBeats: 6,
              position: const Duration(seconds: 22),
              total: const Duration(minutes: 5, seconds: 5),
              isPlaying: true,
              caption: caption,
            ),
          ),
        ),
      );

      await tester.pumpWidget(stage(null));
      final withoutCaption = tester.getRect(
        find.byKey(const ValueKey('video-surface')),
      );

      await tester.pumpWidget(
        stage(
          "I'll guide you through a short relaxation exercise using gentle "
          'breathing and present-moment awareness.',
        ),
      );
      await tester.pump();
      final withCaption = tester.getRect(
        find.byKey(const ValueKey('video-surface')),
      );

      expect(withCaption, withoutCaption);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mood chart exposes adjustable day values', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoodTrendChart(
            data: [
              DailyAverage(DateTime(2026, 9, 20), 2.5),
              DailyAverage(DateTime(2026, 9, 21), null),
              DailyAverage(DateTime(2026, 9, 22), 4),
            ],
          ),
        ),
      ),
    );

    var chart = tester.getSemantics(find.bySemanticsLabel('Mood trend chart'));
    expect(chart.value, contains('20 Sep, 2.5 out of 5'));
    expect(chart.increasedValue, '20 September, 2.5 out of 5');
    expect(chart.decreasedValue, '22 September, 4.0 out of 5');
    expect(
      chart.getSemanticsData().hasAction(SemanticsAction.increase),
      isTrue,
    );
    expect(
      chart.getSemanticsData().hasAction(SemanticsAction.decrease),
      isTrue,
    );

    semantics.dispose();
  });
}
