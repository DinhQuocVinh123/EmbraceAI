import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../data/session_script.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../models/session_answers.dart';
import '../models/session_scene.dart';
import '../services/ask_service.dart';
import '../state/journal_store.dart';
import '../state/settings_store.dart';
import '../widgets/session_sound_controls.dart';
import 'ask_screen.dart';
import 'session_screen.dart';

/// Trang mở đầu: giải thích hoạt động trước khi bắt đầu.
///
/// Dr. Ramis đề nghị có trang này — người dùng cần biết mình sắp làm gì,
/// mất bao lâu, và dừng được lúc nào, trước khi video chạy.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsStore>();
    final l10n = context.l10n;

    // Nút Begin ghim ở đáy để luôn nằm trong tầm nhìn: người dùng không phải
    // cuộn qua phần cài đặt mới tìm thấy việc chính. Cài đặt chi tiết gom vào
    // một thẻ thu gọn; nút "dễ nhìn" vẫn để ngoài cho người cần chữ to.
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.welcomeTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
                Gap.s,
                Text(
                  l10n.welcomeIntro,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                Gap.l,
                const _ExpectationList(),
                Gap.l,
                _ScenePicker(settings: settings),
                Gap.l,
                _EasierViewCard(settings: settings),
                Gap.l,
                _SoundAndDisplayCard(settings: settings),
                const _AskEntry(),
              ],
            ),
          ),
          _BeginBar(onBegin: () => _start(context, settings.scene)),
        ],
      ),
    );
  }

  Future<void> _start(BuildContext context, SessionScene scene) async {
    final store = context.read<JournalStore>();
    final messenger = ScaffoldMessenger.of(context);
    final snackBarAnimationStyle = AppMotion.style(context);
    final l10n = context.l10n;
    final outcome = await SessionScreen.open(context, scene);
    if (outcome == null) return;
    final answers = outcome.answers;

    if (!outcome.saveToJournal) {
      // Không lưu ghi chú, nhưng buổi tập vẫn được tính cho nghiên cứu.
      if (answers.practiceStarted) {
        await store.recordUnsavedSession(
          occurredAt: answers.startedAt,
          moodAfter: answers.moodAfter,
          reflectionProvided: answers.reflection?.trim().isNotEmpty ?? false,
        );
      }
      return;
    }

    await store.save(_toEntry(answers, l10n));
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.welcomeSessionSaved)),
      snackBarAnimationStyle: snackBarAnimationStyle,
    );
  }

  /// Buổi thiền chảy thẳng vào cuốn nhật ký sẵn có — cùng một dòng thời gian,
  /// nên biểu đồ tâm trạng phản ánh cả những lần tập. Ghi chú viết bằng ngôn
  /// ngữ đang dùng lúc lưu; nhãn "Session" là mã nên giữ nguyên.
  JournalEntry _toEntry(SessionAnswers a, AppLocalizations l10n) {
    final lines = <String>[
      if (a.reflection != null && a.reflection!.trim().isNotEmpty)
        a.reflection!.trim(),
      if (a.question != null && a.question!.trim().isNotEmpty)
        l10n.journalLineQuestion(a.question!.trim()),
      if (a.levelBefore != null && a.levelAfter != null)
        l10n.journalLineLevel(
          (a.feeling ?? CheckInFeeling.stressed).scaleName(l10n),
          a.levelBefore!,
          a.levelAfter!,
        ),
    ];
    return JournalEntry(
      mood: a.moodAfter,
      note: lines.join('\n'),
      tags: const ['Session'],
      createdAt: a.startedAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Lối vào Ask EmbraceAI. Chỉ hiện với tài khoản được bật dùng thử
/// (`ai_enabled`); mọi tài khoản khác không thấy gì thay đổi.
class _AskEntry extends StatefulWidget {
  const _AskEntry();

  @override
  State<_AskEntry> createState() => _AskEntryState();
}

class _AskEntryState extends State<_AskEntry> {
  AskService? _service;
  Future<bool>? _enabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enabled != null) return;
    try {
      _service = context.read<AskService>();
      _enabled = _service!.isEnabled();
    } on ProviderNotFoundException {
      _enabled = Future.value(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _enabled,
      builder: (context, snapshot) {
        final service = _service;
        if (snapshot.data != true || service == null) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => AskScreen.open(context, service),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    Gap.m,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.welcomeAskTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Gap.xs,
                          Text(
                            context.l10n.welcomeAskSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Nút bắt đầu, ghim ở đáy tab nên luôn nhìn thấy dù danh sách dài.
class _BeginBar extends StatelessWidget {
  const _BeginBar({required this.onBegin});

  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onBegin,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(context.l10n.welcomeBegin),
              ),
            ),
            Gap.xs,
            Text(
              context.l10n.welcomeStopAnyTime,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Một chạm để chuyển sang chữ to và hình rõ: để ngoài, không giấu trong
/// phần cài đặt, vì người cần nó nhất cũng là người khó tìm nó nhất.
class _EasierViewCard extends StatelessWidget {
  const _EasierViewCard({required this.settings});

  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.accessibility_new,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                Gap.s,
                Text(
                  context.l10n.welcomeEasierTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Gap.s,
            Text(
              context.l10n.welcomeEasierBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.m,
            FilledButton.tonalIcon(
              onPressed: settings.isAssisted
                  ? settings.resetView
                  : settings.enableAssistedView,
              icon: Icon(
                settings.isAssisted
                    ? Icons.check_circle
                    : Icons.visibility_outlined,
              ),
              label: Text(
                settings.isAssisted
                    ? context.l10n.welcomeEasierOn
                    : context.l10n.welcomeEasierTurnOn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpectationList extends StatelessWidget {
  const _ExpectationList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final items = [
      (Icons.schedule, l10n.welcomeExpectTimeTitle, l10n.welcomeExpectTimeBody),
      (
        Icons.touch_app_outlined,
        l10n.welcomeExpectFlowTitle,
        l10n.welcomeExpectFlowBody,
      ),
      (
        Icons.headphones_outlined,
        l10n.welcomeExpectHeadphonesTitle,
        l10n.welcomeExpectHeadphonesBody,
      ),
      (
        Icons.pause_circle_outline,
        l10n.welcomeExpectStopTitle,
        l10n.welcomeExpectStopBody,
      ),
    ];
    return Column(
      children: [
        for (final (icon, title, sub) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: theme.colorScheme.primary),
                Gap.m,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        sub,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Chọn bối cảnh.
///
/// Hội đồng nghi ngại một bối cảnh cố định là làng quê Việt Nam chưa chắc gần
/// gũi số đông (Dr. Tuan, Dr. Silas). Cả hai bản dùng chung kịch bản và mốc
/// thời gian, chỉ khác phần hình.
class _ScenePicker extends StatelessWidget {
  const _ScenePicker({required this.settings});

  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                Gap.s,
                Text(
                  context.l10n.welcomeSceneTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Gap.s,
            Text(
              context.l10n.welcomeSceneBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.m,
            for (final scene in SessionScene.values) ...[
              _SceneOption(
                scene: scene,
                selected: settings.scene == scene,
                onTap: () => settings.setScene(scene),
              ),
              if (scene != SessionScene.values.last) Gap.s,
            ],
          ],
        ),
      ),
    );
  }
}

class _SceneOption extends StatelessWidget {
  const _SceneOption({
    required this.scene,
    required this.selected,
    required this.onTap,
  });

  final SessionScene scene;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: scene.label(l10n),
      hint: scene.description(l10n),
      onTap: onTap,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.fast),
          curve: Curves.easeOutCubic,
          // Ô đang chọn: viền nhấn và nền nhấn nhạt; ô chưa chọn: nền trang và
          // viền mảnh — khác nhau cả về viền lẫn dấu tích, không chỉ màu nền.
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.4)
                : scheme.surface,
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.lg,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.lg,
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.md,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            scene.swatch,
                            Color.lerp(scene.swatch, Colors.black, 0.45)!,
                          ],
                        ),
                      ),
                    ),
                    Gap.m,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scene.label(l10n),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          Text(
                            scene.description(l10n),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: AnimatedSwitcher(
                        duration: AppMotion.duration(context, AppMotion.fast),
                        child: selected
                            ? Icon(
                                Icons.check_circle,
                                key: const ValueKey('selected'),
                                color: scheme.primary,
                              )
                            : const SizedBox(key: ValueKey('not-selected')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cài đặt chi tiết, thu gọn mặc định: âm thanh, cỡ chữ, phụ đề, chuyển động.
/// Dòng tóm tắt cho biết đang chọn gì mà không cần mở ra.
class _SoundAndDisplayCard extends StatelessWidget {
  const _SoundAndDisplayCard({required this.settings});

  final SettingsStore settings;

  static String _duration(AppLocalizations l10n, Duration d) =>
      l10n.durationMinSec(d.inMinutes, d.inSeconds % 60);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.tune, color: theme.colorScheme.primary),
        title: Text(
          l10n.welcomeSoundDisplayTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _summary(l10n, settings),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        expansionAnimationStyle: AppMotion.style(context),
        children: [
          SessionSoundControls(settings: settings),
          const Divider(height: 32),
          Text(l10n.welcomeTextSize, style: theme.textTheme.labelLarge),
          Gap.s,
          Wrap(
            spacing: 8,
            children: [
              for (final s in SettingsStore.textScaleSteps)
                ChoiceChip(
                  label: Text(l10n.percentValue((s * 100).round())),
                  selected: settings.textScale == s,
                  onSelected: (_) => settings.setTextScale(s),
                ),
            ],
          ),
          Gap.m,
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.captionsOn,
            onChanged: settings.setCaptionsOn,
            title: Text(l10n.welcomeShowCaptions),
            subtitle: Text(
              l10n.welcomeShowCaptionsBody,
              style: theme.textTheme.bodySmall,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.reduceMotion,
            onChanged: settings.setReduceMotion,
            title: Text(l10n.welcomeReduceMotion),
            subtitle: Text(
              l10n.welcomeReduceMotionBody,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Gap.s,
          Text(
            l10n.welcomeDurations(
              _duration(l10n, SessionScript.practiceDuration(short: true)),
              _duration(l10n, SessionScript.practiceDuration()),
              _duration(
                l10n,
                SessionScript.practiceDuration(breathingOnly: true),
              ),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _summary(AppLocalizations l10n, SettingsStore s) => [
    s.soundOn ? l10n.welcomeSummaryVoiceOn : l10n.welcomeSummaryVoiceOff,
    s.backgroundSound.label(l10n),
    l10n.welcomeSummaryText((s.textScale * 100).round()),
    s.captionsOn
        ? l10n.welcomeSummaryCaptionsOn
        : l10n.welcomeSummaryCaptionsOff,
  ].join(' · ');
}
