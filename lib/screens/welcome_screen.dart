import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../data/session_script.dart';
import '../models/journal_entry.dart';
import '../models/session_answers.dart';
import '../models/session_scene.dart';
import '../state/journal_store.dart';
import '../state/settings_store.dart';
import '../widgets/session_sound_controls.dart';
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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          Semantics(
            header: true,
            child: Text(
              'A quiet moment',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          Gap.s,
          Text(
            'A guided relaxation for the time around appointments and test '
            'results. All you need to do is sit still and follow along.',
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
          _SoundCard(settings: settings),
          Gap.l,
          _ConfigCard(settings: settings),
          Gap.l,
          FilledButton.icon(
            onPressed: () => _start(context, settings.scene),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Begin'),
          ),
          Gap.s,
          Center(
            child: Text(
              'You can stop at any time.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _start(BuildContext context, SessionScene scene) async {
    final store = context.read<JournalStore>();
    final messenger = ScaffoldMessenger.of(context);
    final snackBarAnimationStyle = AppMotion.style(context);
    final answers = await SessionScreen.open(context, scene);
    if (answers == null) return;

    await store.save(_toEntry(answers));
    messenger.showSnackBar(
      const SnackBar(content: Text('Session saved to your journal')),
      snackBarAnimationStyle: snackBarAnimationStyle,
    );
  }

  /// Buổi thiền chảy thẳng vào cuốn nhật ký sẵn có — cùng một dòng thời gian,
  /// nên biểu đồ tâm trạng phản ánh cả những lần tập.
  JournalEntry _toEntry(SessionAnswers a) {
    final lines = <String>[
      if (a.reflection != null && a.reflection!.trim().isNotEmpty)
        a.reflection!.trim(),
      if (a.question != null && a.question!.trim().isNotEmpty)
        'Question for the team: ${a.question!.trim()}',
      if (a.stressBefore != null && a.stressAfter != null)
        'Stress: ${a.stressBefore} → ${a.stressAfter}',
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

class _SoundCard extends StatelessWidget {
  const _SoundCard({required this.settings});

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
                  Icons.headphones_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                Gap.s,
                Text(
                  'Sound',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Gap.s,
            SessionSoundControls(settings: settings),
          ],
        ),
      ),
    );
  }
}

class _ExpectationList extends StatelessWidget {
  const _ExpectationList();

  static const _items = [
    (
      Icons.schedule,
      'Choose 3 or 5 to 6 minutes',
      'A little time for yourself',
    ),
    (
      Icons.touch_app_outlined,
      'Before and after',
      'A check-in, uninterrupted practice, then time to reflect',
    ),
    (Icons.headphones_outlined, 'Headphones help', 'But are not required'),
    (Icons.pause_circle_outline, 'Stop any time', 'Nothing is lost'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (icon, title, sub) in _items)
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
                  'Setting',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Gap.s,
            Text(
              'Choose what you would like to look at. The practice itself is '
              'the same.',
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
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: scene.label,
      hint: scene.description,
      onTap: onTap,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.fast),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
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
                            scene.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          Text(
                            scene.description,
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

/// Phần tuỳ chỉnh trước khi bắt đầu — ứng với trang "Configuration".
class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.settings});

  final SettingsStore settings;

  static String _duration(Duration d) =>
      '${d.inMinutes} min ${d.inSeconds % 60} sec';

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
                  'Easier to see',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Gap.s,
            Text(
              'If small text is hard to read, or the picture looks hazy, turn '
              'this on.',
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
                    ? 'Easier view is on'
                    : 'Turn on easier view',
              ),
            ),
            Gap.m,
            Text('Text size', style: theme.textTheme.labelLarge),
            Gap.s,
            Wrap(
              spacing: 8,
              children: [
                for (final s in SettingsStore.textScaleSteps)
                  ChoiceChip(
                    label: Text('${(s * 100).round()}%'),
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
              title: const Text('Show captions'),
              subtitle: Text(
                'Writes out what is being said, at the size you chose',
                style: theme.textTheme.bodySmall,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.reduceMotion,
              onChanged: settings.setReduceMotion,
              title: const Text('Reduce motion'),
              subtitle: Text(
                'Removes non-essential fades and page movement',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Gap.s,
            Text(
              'Short ${_duration(SessionScript.practiceDuration(short: true))} · '
              'Full ${_duration(SessionScript.practiceDuration())} with grounding '
              'or ${_duration(SessionScript.practiceDuration(breathingOnly: true))} with breathing',
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
