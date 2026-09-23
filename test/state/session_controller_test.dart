import 'package:embrace_ai/data/session_script.dart';
import 'package:embrace_ai/models/beat.dart';
import 'package:embrace_ai/models/breathing_cue.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:embrace_ai/models/session_answers.dart';
import 'package:embrace_ai/models/session_audio.dart';
import 'package:embrace_ai/models/session_scene.dart';
import 'package:embrace_ai/state/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../support/fake_video_player.dart';

void main() {
  late FakeVideoPlayerPlatform fake;
  setUp(() {
    fake = FakeVideoPlayerPlatform(duration: SessionScript.totalDuration);
    VideoPlayerPlatform.instance = fake;
  });

  Future<void> withSession(
    WidgetTester tester,
    Future<void> Function(SessionController) body, {
    SessionScene scene = SessionScene.countryside,
    double voiceVolume = 0.70,
    BackgroundSound backgroundSound = BackgroundSound.none,
    double backgroundVolume = 0.70,
  }) async {
    final c = SessionController(
      scene: scene,
      voiceVolume: voiceVolume,
      backgroundSound: backgroundSound,
      backgroundVolume: backgroundVolume,
    );
    await c.init();
    try {
      expect(c.isReady, isTrue);
      await body(c);
    } finally {
      c.dispose();
      await tester.pump();
    }
  }

  Future<void> begin(
    SessionController c, [
    PracticeChoice practice = PracticeChoice.grounding,
    PracticeLength practiceLength = PracticeLength.full,
  ]) async {
    await c.answerSafety(SafetyAnswer.yes);
    await c.answerCheckIn(
      feeling: CheckInFeeling.stressed,
      stress: 8,
      practice: practice,
      practiceLength: practiceLength,
    );
  }

  testWidgets('preparation is silent and precedes playback', (tester) async {
    await withSession(tester, (c) async {
      expect(c.phase, SessionPhase.safety);
      expect(fake.isPlaying, isFalse);
      await c.answerSafety(SafetyAnswer.yes);
      expect(c.phase, SessionPhase.checkIn);
      expect(fake.isPlaying, isFalse);
      await c.answerCheckIn(
        feeling: CheckInFeeling.calm,
        stress: 2,
        practice: PracticeChoice.grounding,
        practiceLength: PracticeLength.full,
      );
      expect(c.phase, SessionPhase.practice);
      expect(fake.isPlaying, isTrue);
      expect(fake.position, Duration.zero);
    });
  });

  testWidgets('declining safety never starts the video', (tester) async {
    await withSession(tester, (c) async {
      await c.answerSafety(SafetyAnswer.no);
      expect(c.isFinished, isTrue);
      expect(fake.isPlaying, isFalse);
      expect(c.answers.finishedAt, isNotNull);
    });
  });

  testWidgets('volume is applied on init and can change during a session', (
    tester,
  ) async {
    await withSession(tester, (c) async {
      expect(fake.volume, 0.35);
      await c.updateAudio(
        voiceVolume: 0,
        backgroundSound: BackgroundSound.none,
        backgroundVolume: 0.70,
      );
      expect(fake.volume, 0);
      await c.updateAudio(
        voiceVolume: 1,
        backgroundSound: BackgroundSound.none,
        backgroundVolume: 0.70,
      );
      expect(fake.volume, 1);
    }, voiceVolume: 0.35);
  });

  testWidgets('background sound has independent playback and volume', (
    tester,
  ) async {
    const sound = BackgroundSound.ocean;
    final asset = sound.assetFor(SessionScene.countryside)!;
    await withSession(
      tester,
      (c) async {
        expect(fake.opened, [SessionScene.countryside.asset, asset]);
        expect(fake.mixWithOthersValues, everyElement(isTrue));
        expect(fake.volume, 0.35);
        expect(fake.volumeFor(asset), 1);

        await begin(c);
        expect(fake.isPlaying, isTrue);
        expect(fake.isPlayingSource(asset), isTrue);

        fake.position = const Duration(seconds: 12);
        await tester.pump(const Duration(milliseconds: 600));
        await c.togglePlay();
        expect(fake.isPlaying, isFalse);
        expect(fake.isPlayingSource(asset), isFalse);

        await c.togglePlay();
        expect(fake.positionFor(asset), c.sourcePosition);
        expect(fake.isPlayingSource(asset), isTrue);
      },
      voiceVolume: 0.35,
      backgroundSound: sound,
      backgroundVolume: 1,
    );
  });

  testWidgets('background sound can be replaced while practice is paused', (
    tester,
  ) async {
    const original = BackgroundSound.countryside;
    const replacement = BackgroundSound.rain;
    final originalAsset = original.assetFor(SessionScene.countryside)!;
    final replacementAsset = replacement.assetFor(SessionScene.countryside)!;
    await withSession(tester, (c) async {
      await begin(c);
      fake.position = const Duration(seconds: 12);
      await tester.pump(const Duration(milliseconds: 600));
      await c.togglePlay();
      final update = c.updateAudio(
        voiceVolume: 0.70,
        backgroundSound: replacement,
        backgroundVolume: 0.35,
      );
      var completed = false;
      final tracked = update.then((_) => completed = true);
      for (var i = 0; i < 20 && !completed; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(completed, isTrue);
      await tracked;

      expect(fake.opened, containsAll([originalAsset, replacementAsset]));
      expect(fake.volumeFor(replacementAsset), 0.35);
      expect(fake.positionFor(replacementAsset), c.sourcePosition);
      expect(fake.isPlayingSource(replacementAsset), isFalse);
    }, backgroundSound: original);
  });

  testWidgets('preparation can be skipped without inventing answers', (
    tester,
  ) async {
    await withSession(tester, (c) async {
      await c.skipQuestion();
      await c.skipQuestion();
      expect(c.phase, SessionPhase.practice);
      expect(c.answers.stressBefore, isNull);
      expect(c.answers.feeling, isNull);
      expect(fake.isPlaying, isTrue);
    });
  });

  for (final length in PracticeLength.values) {
    for (final practice in PracticeChoice.values) {
      testWidgets('$length $practice skips unused ranges and tracks progress', (
        tester,
      ) async {
        await withSession(tester, (c) async {
          await begin(c, practice, length);
          final firstExercise = practice == PracticeChoice.breathing ? 155 : 95;
          expect(
            c.plannedBeats.every((b) => b.interaction == BeatInteraction.none),
            isTrue,
          );
          expect(
            c.total.inSeconds,
            length == PracticeLength.short
                ? 200
                : practice == PracticeChoice.breathing
                ? 305
                : 365,
          );
          await runTo(tester, fake, const Duration(seconds: 45));
          expect(fake.seeks.last, Duration(seconds: firstExercise));
          expect(c.position, const Duration(seconds: 45));
          expect(c.phase, SessionPhase.practice);
          expect(fake.isPlaying, isTrue);
          await runTo(tester, fake, const Duration(seconds: 380));
          expect(fake.seeks.last, const Duration(seconds: 425));
          expect(c.currentBeat.id, 'closing');
          expect(c.phase, SessionPhase.practice);
          expect(fake.isPlaying, isTrue);
          await runTo(tester, fake, const Duration(seconds: 460));
          expect(c.phase, SessionPhase.feedback);
          expect(c.isFinished, isFalse);
          expect(c.position, c.total);
          expect(c.answers.practiceLength, length);
          expect(fake.isPlaying, isFalse);
        });
      });
    }
  }

  testWidgets('captions use source position after a skipped range', (
    tester,
  ) async {
    await withSession(tester, (c) async {
      await begin(c);
      var notifications = 0;
      c.addListener(() => notifications++);
      await runTo(tester, fake, const Duration(seconds: 7));
      expect(c.activeCaption?.text, 'Hello. Welcome.');
      expect(notifications, greaterThan(1));
      await runTo(tester, fake, const Duration(seconds: 97));
      expect(c.position.inSeconds, 47);
      expect(c.activeCaption?.text, contains('settle where you are'));
    });
  });

  testWidgets('breathing cue follows five-second inhale and exhale phases', (
    tester,
  ) async {
    await withSession(tester, (c) async {
      await begin(c);
      await runTo(tester, fake, const Duration(seconds: 157));
      expect(c.breathingCue?.phase, BreathingPhase.inhale);
      expect(c.breathingCue?.progress, closeTo(0.4, 0.01));

      await runTo(tester, fake, const Duration(seconds: 162));
      expect(c.breathingCue?.phase, BreathingPhase.exhale);
      expect(c.breathingCue?.progress, closeTo(0.4, 0.01));
    });
  });

  testWidgets('a late completion tick still presents feedback exactly once', (
    tester,
  ) async {
    await withSession(tester, (c) async {
      await begin(c);
      fake.position = const Duration(milliseconds: 479800);
      await tester.pump(const Duration(seconds: 1));
      expect(c.phase, SessionPhase.feedback);
      final finishedAt = c.answers.finishedAt;
      await tester.pump(const Duration(seconds: 2));
      expect(c.phase, SessionPhase.feedback);
      expect(c.answers.finishedAt, finishedAt);
      expect(c.isFinished, isFalse);
    });
  });

  testWidgets(
    'feedback then care-team question then summary preserve answers',
    (tester) async {
      await withSession(tester, (c) async {
        await begin(c);
        await c.stopEarly();
        expect(c.phase, SessionPhase.feedback);
        await c.answerFeedback(
          mood: Mood.great,
          stressAfter: 3,
          reflection: 'My shoulders relaxed.',
        );
        expect(c.phase, SessionPhase.question);
        expect(c.isFinished, isFalse);
        await c.answerQuestion(' What should I ask next time? ');
        expect(c.isFinished, isTrue);
        expect(c.answers.reflection, 'My shoulders relaxed.');
        expect(c.answers.moodAfter, Mood.great);
        expect(c.answers.question, 'What should I ask next time?');
        expect(c.answers.stressDelta, 5);
        expect(c.answers.safety, SafetyAnswer.yes);
        expect(fake.isPlaying, isFalse);
      });
    },
  );

  testWidgets('both after-practice questions are optional', (tester) async {
    await withSession(tester, (c) async {
      await begin(c);
      await c.stopEarly();
      await c.skipQuestion();
      expect(c.phase, SessionPhase.question);
      await c.skipQuestion();
      expect(c.isFinished, isTrue);
      expect(c.answers.stressAfter, isNull);
      expect(c.answers.reflection, isNull);
    });
  });

  for (final playing in [true, false]) {
    testWidgets('closing help restores playing=$playing', (tester) async {
      await withSession(tester, (c) async {
        await begin(c);
        await runTo(tester, fake, const Duration(seconds: 10));
        if (!playing) await c.togglePlay();
        final position = fake.position;
        final wasPlaying = await c.pauseForOverlay();
        expect(fake.isPlaying, isFalse);
        await c.resumeAfterOverlay(wasPlaying);
        expect(fake.isPlaying, playing);
        expect(fake.position, position);
      });
    });
  }

  testWidgets('ending through help cannot resume video behind feedback', (
    tester,
  ) async {
    await withSession(tester, (c) async {
      await begin(c);
      final wasPlaying = await c.pauseForOverlay();
      await c.stopEarly();
      await c.resumeAfterOverlay(wasPlaying);
      await c.togglePlay();
      expect(fake.isPlaying, isFalse);
      expect(c.phase, SessionPhase.feedback);
    });
  });

  testWidgets('a delayed overlay close is safe after disposal', (tester) async {
    final c = SessionController();
    await c.init();
    await begin(c);
    final wasPlaying = await c.pauseForOverlay();
    c.dispose();
    await c.resumeAfterOverlay(wasPlaying);
    await tester.pump();
    expect(fake.isPlaying, isFalse);
  });

  testWidgets('both scenes use the same practice plan with their own asset', (
    tester,
  ) async {
    final plans = <List<String>>[];
    for (final scene in SessionScene.values) {
      await withSession(tester, (c) async {
        plans.add(c.plannedBeats.map((b) => b.id).toList());
      }, scene: scene);
    }
    expect(plans.first, plans.last);
    expect(fake.opened, SessionScene.values.map((s) => s.asset).toList());
  });
}
