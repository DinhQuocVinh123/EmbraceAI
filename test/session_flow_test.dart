import 'package:embrace_ai/core/theme.dart';
import 'package:embrace_ai/data/session_script.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:embrace_ai/models/session_answers.dart';
import 'package:embrace_ai/models/session_audio.dart';
import 'package:embrace_ai/models/session_scene.dart';
import 'package:embrace_ai/screens/session_screen.dart';
import 'package:embrace_ai/state/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'support/fake_video_player.dart';

void main() {
  late FakeVideoPlayerPlatform fake;
  late SettingsStore settings;
  SessionAnswers? saved;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsStore();
    fake = FakeVideoPlayerPlatform(duration: SessionScript.totalDuration);
    VideoPlayerPlatform.instance = fake;
    saved = null;
  });

  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        160,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await settings.setTextScale(scale);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: Builder(
          builder: (context) {
            final textScale = context.watch<SettingsStore>().textScale;
            return MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: FilledButton(
                    onPressed: () async {
                      saved = await SessionScreen.open(
                        context,
                        SessionScene.countryside,
                      );
                    },
                    child: const Text('Open session'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tap(tester, 'Open session');
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  Future<void> begin(WidgetTester tester) async {
    await tap(tester, 'Yes, I can sit quietly');
    await tap(tester, 'Calm');
    await tap(tester, 'Continue');
    await tap(tester, 'Grounding');
    expect(find.text('How much time would you like?'), findsOneWidget);
    await tap(tester, 'Full practice');
  }

  testWidgets('short duration is selected before playback', (tester) async {
    await open(tester);
    await tap(tester, 'Yes, I can sit quietly');
    await tap(tester, 'Calm');
    await tap(tester, 'Continue');
    await tap(tester, 'Follow the breath');
    expect(find.text('3 min 20 sec'), findsOneWidget);
    await tap(tester, 'Short practice');
    expect(find.byTooltip('Help'), findsOneWidget);
    expect(fake.isPlaying, isTrue);
  });

  testWidgets('complete session shows feedback and saves reflection', (
    tester,
  ) async {
    await open(tester);
    expect(fake.isPlaying, isFalse);
    await begin(tester);
    expect(find.byTooltip('Help'), findsOneWidget);
    fake.position = const Duration(seconds: 460);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('How do you feel now?'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    await tap(tester, 'Really good');
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextField), 'I noticed my breathing.');
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextField), 'What happens next?');
    await tap(tester, 'Save and continue');
    expect(find.text('Done'), findsOneWidget);
    await tap(tester, 'Save to journal');
    expect(saved?.reflection, 'I noticed my breathing.');
    expect(saved?.question, 'What happens next?');
    expect(saved?.stressAfter, isNotNull);
    expect(saved?.moodAfter, Mood.great);
  });

  testWidgets('help returns to the prior pause state and applies settings', (
    tester,
  ) async {
    await open(tester);
    await begin(tester);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Help'));
    await tester.pumpAndSettle();
    expect(fake.volume, SoundLevel.normal.volume);
    await tap(tester, 'Guided voice');
    expect(settings.soundOn, isFalse);
    expect(fake.volume, 0);
    await tap(tester, 'Guided voice');
    await tap(tester, 'Quiet');
    expect(settings.soundLevel, SoundLevel.quiet);
    expect(fake.volume, SoundLevel.quiet.volume);
    await tap(tester, 'Gentle rain');
    expect(settings.backgroundSound, BackgroundSound.rain);
    final rainAsset = BackgroundSound.rain.assetFor(SessionScene.countryside)!;
    await tester.runAsync(() async {
      for (var i = 0; i < 20 && !fake.opened.contains(rainAsset); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    expect(fake.opened, contains(rainAsset));
    expect(fake.volumeFor(rainAsset), SoundLevel.normal.volume);
    await tap(tester, 'Easier view');
    expect(settings.highClarity, isTrue);
    expect(settings.textScale, 1.5);
    await tester.tap(find.byTooltip('Close help'));
    await tester.pumpAndSettle();
    expect(fake.isPlaying, isFalse);
    await tester.tap(find.byTooltip('Resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Help'));
    await tester.pumpAndSettle();
    expect(fake.isPlaying, isFalse);
    await tap(tester, 'Return to practice');
    expect(fake.isPlaying, isTrue);
  });

  testWidgets('help can end practice and all final questions can be skipped', (
    tester,
  ) async {
    await open(tester);
    await begin(tester);
    await tester.tap(find.byTooltip('Help'));
    await tester.pumpAndSettle();
    await tap(tester, 'End practice');
    expect(find.text('How do you feel now?'), findsOneWidget);
    expect(fake.isPlaying, isFalse);
    await tap(tester, 'Skip this question');
    await tap(tester, 'Skip this question');
    await tap(tester, 'Skip this question');
    await tap(tester, 'Skip this question');
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('skipping reflection keeps the mood already selected', (
    tester,
  ) async {
    await open(tester);
    await begin(tester);
    await tester.tap(find.byTooltip('Help'));
    await tester.pumpAndSettle();
    await tap(tester, 'End practice');

    await tap(tester, 'Really good');
    await tap(tester, 'Continue');
    await tap(tester, 'Skip this question');
    await tap(tester, 'Skip this question');
    await tap(tester, 'Save to journal');

    expect(saved?.moodAfter, Mood.great);
    expect(saved?.stressAfter, isNotNull);
    expect(saved?.reflection, '');
  });

  testWidgets('keyboard shortcuts pause, open help and request stop', (
    tester,
  ) async {
    await open(tester);
    await begin(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(fake.isPlaying, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    expect(find.text('Help'), findsOneWidget);
    await tester.tap(find.byTooltip('Close help'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Stop the session?'), findsOneWidget);
    await tap(tester, 'Keep going');
    expect(fake.isPlaying, isFalse);
  });

  testWidgets('large text keeps preparation help and feedback reachable', (
    tester,
  ) async {
    await open(tester, scale: 2);
    await begin(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Help'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tap(tester, 'Gentle rain');
    await tap(tester, 'High');
    expect(settings.backgroundSound, BackgroundSound.rain);
    expect(settings.backgroundLevel, SoundLevel.louder);
    await tap(tester, 'End practice');
    await tap(tester, 'Really good');
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    await tap(tester, 'Skip this question');
    expect(find.text('Done'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
