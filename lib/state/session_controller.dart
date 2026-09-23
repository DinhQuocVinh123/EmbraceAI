import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart' hide Caption;

import '../data/session_script.dart';
import '../models/beat.dart';
import '../models/breathing_cue.dart';
import '../models/mood.dart';
import '../models/session_audio.dart';
import '../models/session_answers.dart';
import '../models/session_scene.dart';

enum SessionPhase { safety, checkIn, practice, feedback, question, summary }

/// Questions surround the practice; only practice segments play in the video.
class SessionController extends ChangeNotifier {
  SessionController({
    this.scene = SessionScene.countryside,
    double voiceVolume = 0.70,
    this.backgroundSound = BackgroundSound.none,
    double backgroundVolume = 0.70,
  }) : _voiceVolume = voiceVolume,
       _backgroundVolume = backgroundVolume;

  final SessionScene scene;
  final SessionAnswers answers = SessionAnswers();
  VideoPlayerController? _video;
  VideoPlayerController? get video => _video;
  VideoPlayerController? _background;
  BackgroundSound backgroundSound;
  SessionPhase _phase = SessionPhase.safety;
  SessionPhase get phase => _phase;
  Beat _current = SessionScript.beats.first;
  Beat get currentBeat => _current;
  bool _ready = false;
  bool _disposed = false;
  bool _seeking = false;
  double _voiceVolume;
  double _backgroundVolume;
  int _backgroundGeneration = 0;
  Object? _error;

  bool get isReady => _ready;
  bool get isFinished => _phase == SessionPhase.summary;
  bool get isPlaying => _video?.value.isPlaying ?? false;
  Object? get error => _error;
  Duration get sourcePosition => _video?.value.position ?? Duration.zero;

  List<Beat> get plannedBeats => SessionScript.practiceBeats(
    breathingOnly: answers.practice == PracticeChoice.breathing,
    short: answers.practiceLength == PracticeLength.short,
  );

  Duration get total =>
      plannedBeats.fold(Duration.zero, (sum, b) => sum + b.duration);

  /// Progress excludes source ranges containing questions and skipped exercises.
  Duration get position {
    var elapsed = Duration.zero;
    for (final beat in plannedBeats) {
      if (sourcePosition >= beat.end) {
        elapsed += beat.duration;
      } else if (sourcePosition > beat.start) {
        elapsed += sourcePosition - beat.start;
      }
    }
    return elapsed;
  }

  Caption? get activeCaption => _phase == SessionPhase.practice
      ? _current.captionAt(sourcePosition)
      : null;

  BreathingCue? get breathingCue {
    if (_phase != SessionPhase.practice || _current.id != 'breathing') {
      return null;
    }
    final elapsedMs = sourcePosition.inMilliseconds - _current.start.inMilliseconds;
    if (elapsedMs < 0 || sourcePosition >= _current.end) return null;
    const phaseMs = 5000;
    final phaseIndex = elapsedMs ~/ phaseMs;
    return BreathingCue(
      phase: phaseIndex.isEven
          ? BreathingPhase.inhale
          : BreathingPhase.exhale,
      progress: (elapsedMs % phaseMs) / phaseMs,
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> init() async {
    try {
      final v = VideoPlayerController.asset(
        scene.asset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _video = v;
      await v.initialize();
      await v.setVolume(_voiceVolume);
      await _replaceBackground(backgroundSound);
      if (_disposed) return;
      v.addListener(_tick);
      _ready = true;
      _notify();
    } catch (e) {
      if (_disposed) return;
      _error = e;
      _notify();
    }
  }

  void _tick() {
    final v = _video;
    if (_disposed || v == null) return;
    if (v.value.hasError) {
      _error = v.value.errorDescription;
      _notify();
      return;
    }
    if (_phase != SessionPhase.practice || _seeking) return;
    final plan = plannedBeats;
    final pos = sourcePosition;
    if (pos >= plan.last.end || v.value.isCompleted) {
      _endPractice();
      return;
    }
    final next = plan.firstWhere((b) => pos < b.end);
    _current = next;
    if (pos < next.start) {
      _seek(next.start);
      return;
    }
    _notify();
  }

  Future<void> _seek(Duration target) async {
    _seeking = true;
    try {
      await Future.wait([
        if (_video case final video?) video.seekTo(target),
        if (_background case final background?) background.seekTo(target),
      ]);
    } catch (e) {
      _error = e;
    } finally {
      _seeking = false;
      _notify();
    }
  }

  Future<void> answerSafety(SafetyAnswer value) async {
    if (_phase != SessionPhase.safety) return;
    answers.safety = value;
    if (value == SafetyAnswer.no) {
      answers.finishedAt = DateTime.now();
      _phase = SessionPhase.summary;
    } else {
      _phase = SessionPhase.checkIn;
    }
    _notify();
  }

  Future<void> answerCheckIn({
    required CheckInFeeling feeling,
    required int stress,
    required PracticeChoice practice,
    required PracticeLength practiceLength,
  }) async {
    if (_phase != SessionPhase.checkIn) return;
    answers.feeling = feeling;
    answers.stressBefore = stress;
    answers.practice = practice;
    answers.practiceLength = practiceLength;
    await _startPractice();
  }

  Future<void> _startPractice() async {
    if (!_ready || _disposed) return;
    _phase = SessionPhase.practice;
    _current = plannedBeats.first;
    answers.startedAt = DateTime.now();
    _notify();
    await _playMedia();
  }

  Future<void> _endPractice() async {
    if (_phase != SessionPhase.practice) return;
    // Change phase before pause notifies listeners, so completion happens once.
    _phase = SessionPhase.feedback;
    answers.finishedAt = DateTime.now();
    await _pauseMedia();
    _notify();
  }

  Future<void> answerFeedback({
    Mood? mood,
    int? stressAfter,
    String? reflection,
  }) async {
    if (_phase != SessionPhase.feedback) return;
    answers.moodAfter = mood;
    answers.stressAfter = stressAfter;
    answers.reflection = reflection;
    _phase = SessionPhase.question;
    _notify();
  }

  Future<void> answerQuestion(String text) async {
    if (_phase != SessionPhase.question) return;
    answers.question = text.trim();
    _phase = SessionPhase.summary;
    _notify();
  }

  Future<void> skipQuestion() async {
    switch (_phase) {
      case SessionPhase.safety:
        _phase = SessionPhase.checkIn;
      case SessionPhase.checkIn:
        await _startPractice();
      case SessionPhase.feedback:
        _phase = SessionPhase.question;
      case SessionPhase.question:
        _phase = SessionPhase.summary;
      case SessionPhase.practice:
      case SessionPhase.summary:
        return;
    }
    _notify();
  }

  Future<void> togglePlay() async {
    if (_phase != SessionPhase.practice || _disposed) return;
    if (isPlaying) {
      await _pauseMedia();
    } else {
      await _playMedia();
    }
  }

  Future<void> updateAudio({
    required double voiceVolume,
    required BackgroundSound backgroundSound,
    required double backgroundVolume,
  }) async {
    _voiceVolume = voiceVolume.clamp(0.0, 1.0);
    _backgroundVolume = backgroundVolume.clamp(0.0, 1.0);
    await _video?.setVolume(_voiceVolume);
    if (this.backgroundSound != backgroundSound) {
      this.backgroundSound = backgroundSound;
      await _replaceBackground(backgroundSound);
    } else {
      await _background?.setVolume(_backgroundVolume);
    }
  }

  Future<bool> pauseForOverlay() async {
    final wasPlaying = isPlaying;
    await _pauseMedia();
    return wasPlaying;
  }

  Future<void> resumeAfterOverlay(bool wasPlaying) async {
    if (!_disposed && wasPlaying && _phase == SessionPhase.practice) {
      await _playMedia();
    }
  }

  Future<void> stopEarly() => _endPractice();

  Future<void> _playMedia() async {
    final video = _video;
    if (video == null) return;
    final background = _background;
    if (background != null) {
      await background.seekTo(video.value.position);
      await background.play();
    }
    await video.play();
  }

  Future<void> _pauseMedia() async {
    await Future.wait([
      if (_video case final video?) video.pause(),
      if (_background case final background?) background.pause(),
    ]);
  }

  Future<void> _replaceBackground(BackgroundSound sound) async {
    final generation = ++_backgroundGeneration;
    final previous = _background;
    final asset = sound.assetFor(scene);
    if (asset == null || _disposed || generation != _backgroundGeneration) {
      _background = null;
      if (previous != null) {
        await previous.pause();
        unawaited(previous.dispose());
      }
      return;
    }
    final next = VideoPlayerController.asset(
      asset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    await next.initialize();
    await next.setLooping(true);
    await next.setVolume(_backgroundVolume);
    await next.seekTo(sourcePosition);
    if (_disposed || generation != _backgroundGeneration) {
      await next.dispose();
      return;
    }
    _background = next;
    if (previous != null) {
      await previous.pause();
      unawaited(previous.dispose());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _backgroundGeneration++;
    _video?.removeListener(_tick);
    _video?.dispose();
    _background?.dispose();
    super.dispose();
  }
}
