import 'package:embrace_ai/models/session_audio.dart';
import 'package:embrace_ai/state/settings_store.dart';
import 'package:embrace_ai/widgets/session_sound_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'support/fake_video_player.dart';

void main() {
  testWidgets('background preview plays, changes volume and stops', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsStore();
    final fake = FakeVideoPlayerPlatform(duration: const Duration(minutes: 8));
    VideoPlayerPlatform.instance = fake;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: settings,
              builder: (context, _) => SessionSoundControls(settings: settings),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Preview sound'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final countryside = BackgroundSound.countryside.assetFor(settings.scene)!;
    expect(fake.opened, contains(countryside));
    expect(fake.mixWithOthersValues, everyElement(isTrue));
    expect(fake.positionFor(countryside), const Duration(seconds: 70));
    expect(fake.volumeFor(countryside), SoundLevel.normal.volume);
    expect(fake.isPlayingSource(countryside), isTrue);
    expect(find.text('Stop preview'), findsOneWidget);

    await tester.tap(find.text('High'));
    await tester.pump();
    expect(fake.volumeFor(countryside), SoundLevel.louder.volume);

    await tester.tap(find.text('Stop preview'));
    await tester.pump();
    expect(fake.isPlayingSource(countryside), isFalse);
    expect(find.text('Preview sound'), findsOneWidget);
  });
}
