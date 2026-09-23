import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart' hide Caption;

import '../core/theme.dart';
import '../core/motion.dart';
import '../models/session_answers.dart';
import '../state/session_controller.dart';
import '../models/session_scene.dart';
import '../state/settings_store.dart';
import '../widgets/session_chrome.dart';
import '../widgets/session_prompts.dart';
import '../widgets/session_help.dart';

/// Màn hình chạy buổi thiền: video nền + lớp tương tác do app vẽ.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.scene});

  final SessionScene scene;

  static Future<SessionAnswers?> open(
    BuildContext context,
    SessionScene scene,
  ) {
    return Navigator.of(context).push<SessionAnswers>(
      AppMotion.pageRoute(context, builder: (_) => SessionScreen(scene: scene)),
    );
  }

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final SettingsStore _settings;
  late final SessionController _c;

  @override
  void initState() {
    super.initState();
    _settings = context.read<SettingsStore>();
    _c = SessionController(
      scene: widget.scene,
      voiceVolume: _settings.effectiveVoiceVolume,
      backgroundSound: _settings.backgroundSound,
      backgroundVolume: _settings.effectiveBackgroundVolume,
    );
    _c.init();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    // Cỡ chữ đã được áp ở cấp MaterialApp, chỗ này không nhân thêm lần nữa.
    return ChangeNotifierProvider.value(
      value: _c,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<SessionController>(
          builder: (context, c, _) {
            final Widget content;
            final Object stateKey;
            if (c.error != null) {
              stateKey = 'error';
              content = _ErrorView(error: c.error!);
            } else if (!c.isReady) {
              stateKey = 'loading';
              content = const Center(child: CircularProgressIndicator());
            } else if (c.isFinished) {
              stateKey = SessionPhase.summary;
              content = _SummaryView(answers: c.answers);
            } else if (c.phase != SessionPhase.practice) {
              stateKey = c.phase;
              content = Scaffold(
                appBar: AppBar(
                  title: Text(
                    c.phase == SessionPhase.safety ||
                            c.phase == SessionPhase.checkIn
                        ? 'Before you begin'
                        : 'After your practice',
                  ),
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    key: ValueKey(c.phase),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _PromptFor(controller: c),
                  ),
                ),
              );
            } else {
              stateKey = SessionPhase.practice;
              content = _PlayerView(controller: c, settings: settings);
            }
            return MotionSwitcher(
              child: KeyedSubtree(key: ValueKey(stateKey), child: content),
            );
          },
        ),
      ),
    );
  }
}

class _PlayerView extends StatelessWidget {
  const _PlayerView({required this.controller, required this.settings});

  final SessionController controller;
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final video = controller.video!;
    final beat = controller.currentBeat;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmStop(context, controller);
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space):
              controller.togglePlay,
          const SingleActivator(LogicalKeyboardKey.f1): () =>
              _showHelp(context),
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _confirmStop(context, controller),
        },
        child: Focus(
          autofocus: true,
          child: SessionStage(
            videoSurface: VideoPlayer(video),
            aspectRatio: video.value.aspectRatio,
            beatNumber: controller.plannedBeats.indexOf(beat) + 1,
            beatTitle: beat.title,
            totalBeats: controller.plannedBeats.length,
            position: controller.position,
            total: controller.total,
            isPlaying: controller.isPlaying,
            highClarity: settings.highClarity,
            captionsOn: settings.captionsOn,
            caption: controller.activeCaption?.text,
            breathingCue: controller.breathingCue,
            reduceMotion: settings.reduceMotion,
            onStop: () => _confirmStop(context, controller),
            onHelp: () => _showHelp(context),
            onTogglePlay: controller.togglePlay,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmStop(BuildContext context, SessionController c) async {
    final wasPlaying = await c.pauseForOverlay();
    if (!context.mounted) return;
    final stop = await showDialog<bool>(
      context: context,
      animationStyle: AppMotion.style(context),
      builder: (context) => AlertDialog(
        title: const Text('Stop the session?'),
        content: const Text('You can come back to it any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (stop == true) {
      await c.stopEarly();
    } else {
      await c.resumeAfterOverlay(wasPlaying);
    }
  }

  Future<void> _showHelp(BuildContext context) async {
    final wasPlaying = await controller.pauseForOverlay();
    if (!context.mounted) return;
    final stop = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AppMotion.style(context),
      builder: (_) => SessionHelp(
        settings: settings,
        onAudioChanged: () => controller.updateAudio(
          voiceVolume: settings.effectiveVoiceVolume,
          backgroundSound: settings.backgroundSound,
          backgroundVolume: settings.effectiveBackgroundVolume,
        ),
      ),
    );
    if (stop == true) {
      await controller.stopEarly();
    } else {
      await controller.resumeAfterOverlay(wasPlaying);
    }
  }
}

/// Chọn đúng thẻ hỏi cho beat đang dừng.
class _PromptFor extends StatelessWidget {
  const _PromptFor({required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.phase) {
      SessionPhase.safety => SafetyPrompt(
        onAnswer: controller.answerSafety,
        onSkip: controller.skipQuestion,
      ),
      SessionPhase.checkIn => CheckInPrompt(
        onDone: (feeling, stress, practice, practiceLength) =>
            controller.answerCheckIn(
              feeling: feeling,
              stress: stress,
              practice: practice,
              practiceLength: practiceLength,
            ),
        onSkip: controller.skipQuestion,
      ),
      SessionPhase.question => QuestionPrompt(
        onAnswer: controller.answerQuestion,
        onSkip: controller.skipQuestion,
      ),
      SessionPhase.feedback => FeedbackPrompt(
        stressBefore: controller.answers.stressBefore,
        onDone: (mood, after, reflection) => controller.answerFeedback(
          mood: mood,
          stressAfter: after,
          reflection: reflection,
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Màn hình tổng kết sau buổi tập.
class SummaryView extends StatelessWidget {
  const SummaryView({
    super.key,
    required this.answers,
    this.onSave,
    this.onSkip,
  });

  final SessionAnswers answers;
  final VoidCallback? onSave;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.spa_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            Gap.m,
            Text(
              'Done',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap.m,
            Text(
              answers.closingMessage,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            if (answers.question != null && answers.question!.isNotEmpty) ...[
              Gap.l,
              _SummaryBlock(
                title: 'Question for your appointment',
                body: answers.question!,
              ),
            ],
            if (answers.reflection != null &&
                answers.reflection!.isNotEmpty) ...[
              Gap.m,
              _SummaryBlock(
                title: 'What you noticed',
                body: answers.reflection!,
              ),
            ],
            Gap.xl,
            FilledButton(
              onPressed: onSave,
              child: const Text('Save to journal'),
            ),
            Gap.s,
            TextButton(onPressed: onSkip, child: const Text('Skip saving')),
          ],
        ),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.answers});

  final SessionAnswers answers;

  @override
  Widget build(BuildContext context) {
    return SummaryView(
      answers: answers,
      onSave: () => Navigator.of(context).pop(answers),
      onSkip: () => Navigator.of(context).pop(),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Gap.xs,
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: Colors.white54,
              size: 40,
            ),
            Gap.m,
            const Text(
              'Could not open the session video',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Gap.s,
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            Gap.l,
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
