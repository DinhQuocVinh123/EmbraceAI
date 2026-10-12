import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../data/session_script.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../models/mood.dart';
import '../models/session_answers.dart';

/// Khung chung cho mọi thẻ hỏi chen giữa buổi thiền.
///
/// Cố tình để nút "Skip" ở mọi thẻ: người dùng không bao giờ bị ép trả lời
/// mới được đi tiếp.
class PromptCard extends StatelessWidget {
  const PromptCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onSkip,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Gap.m,
            Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (subtitle != null) ...[
              Gap.xs,
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            Gap.l,
            child,
            if (onSkip != null) ...[
              Gap.s,
              Center(
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(context.l10n.promptSkipQuestion),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Nút lựa chọn cỡ lớn — chiều cao tối thiểu 56 để dễ bấm khi mắt kém.
class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.description,
    this.selected = false,
    this.leading,
  });

  final String label;
  final String? description;
  final VoidCallback onPressed;
  final bool selected;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      hint: description,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.fast),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[leading!, Gap.m],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          if (description != null)
                            Text(
                              description!,
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

/// Beat 2 — kiểm tra người dùng có đang ở chỗ tiếp tục được không.
class MedicalDisclaimerPrompt extends StatelessWidget {
  const MedicalDisclaimerPrompt({
    super.key,
    required this.onAccept,
    required this.onLeave,
  });

  final VoidCallback onAccept;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PromptCard(
      title: context.l10n.disclaimerTitle,
      subtitle: context.l10n.disclaimerSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    color: scheme.onErrorContainer,
                  ),
                  Gap.m,
                  Expanded(
                    child: Text(
                      context.l10n.disclaimerBody,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onErrorContainer,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Gap.l,
          FilledButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(context.l10n.disclaimerAccept),
          ),
          Gap.s,
          TextButton.icon(
            onPressed: onLeave,
            icon: const Icon(Icons.close),
            label: Text(context.l10n.disclaimerLeave),
          ),
        ],
      ),
    );
  }
}

class SafetyPrompt extends StatelessWidget {
  const SafetyPrompt({super.key, required this.onAnswer, this.onSkip});

  final ValueChanged<SafetyAnswer> onAnswer;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return PromptCard(
      title: context.l10n.safetyTitle,
      subtitle: context.l10n.safetyBody,
      onSkip: onSkip,
      child: Column(
        children: [
          for (final a in SafetyAnswer.values) ...[
            ChoiceButton(
              label: a.label(context.l10n),
              onPressed: () => onAnswer(a),
            ),
            if (a != SafetyAnswer.values.last) Gap.s,
          ],
        ],
      ),
    );
  }
}

/// Beat 3 — hỏi trạng thái hiện tại, đo căng thẳng, rồi chọn bài.
///
/// Các trạng thái này hỗ trợ tailoring và không bị quy đổi thành điểm mood.
class CheckInPrompt extends StatefulWidget {
  const CheckInPrompt({super.key, required this.onDone, this.onSkip});

  final void Function(
    CheckInFeeling feeling,
    int stress,
    PracticeChoice practice,
    PracticeLength practiceLength,
  )
  onDone;
  final VoidCallback? onSkip;

  @override
  State<CheckInPrompt> createState() => _CheckInPromptState();
}

class _CheckInPromptState extends State<CheckInPrompt> {
  CheckInFeeling? _feeling;
  PracticeChoice? _practice;
  double _stress = 5;
  int _step = 0;

  static String _duration(AppLocalizations l10n, Duration duration) =>
      l10n.durationMinSec(duration.inMinutes, duration.inSeconds % 60);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = switch (_step) {
      0 => PromptCard(
        title: l10n.checkInFeelingTitle,
        onSkip: widget.onSkip,
        child: Column(
          children: [
            for (final f in CheckInFeeling.values) ...[
              ChoiceButton(
                label: f.label(l10n),
                selected: _feeling == f,
                leading: Text(f.emoji, style: const TextStyle(fontSize: 26)),
                onPressed: () => setState(() {
                  _feeling = f;
                  _step = 1;
                }),
              ),
              if (f != CheckInFeeling.values.last) Gap.s,
            ],
          ],
        ),
      ),
      1 => PromptCard(
        title: l10n.checkInStressTitle,
        subtitle: l10n.checkInStressSubtitle,
        onSkip: widget.onSkip,
        child: Column(
          children: [
            _StressSlider(
              value: _stress,
              onChanged: (v) => setState(() => _stress = v),
            ),
            Gap.l,
            FilledButton(
              onPressed: () => setState(() => _step = 2),
              child: Text(l10n.commonContinue),
            ),
          ],
        ),
      ),
      2 => PromptCard(
        title: _stress >= 7
            ? l10n.checkInSlowerTitle
            : l10n.checkInChooseTitle,
        subtitle: _stress >= 7 ? l10n.checkInSlowerBody : null,
        onSkip: widget.onSkip,
        child: Column(
          children: [
            for (final p in PracticeChoice.values) ...[
              ChoiceButton(
                label: p.label(l10n),
                description: p.description(l10n),
                onPressed: () => setState(() {
                  _practice = p;
                  _step = 3;
                }),
              ),
              if (p != PracticeChoice.values.last) Gap.s,
            ],
          ],
        ),
      ),
      _ => PromptCard(
        title: l10n.checkInLengthTitle,
        subtitle: l10n.checkInLengthSubtitle,
        onSkip: widget.onSkip,
        child: Column(
          children: [
            for (final length in PracticeLength.values) ...[
              ChoiceButton(
                label: length.label(l10n),
                description: _duration(
                  l10n,
                  SessionScript.practiceDuration(
                    breathingOnly: _practice == PracticeChoice.breathing,
                    short: length == PracticeLength.short,
                  ),
                ),
                onPressed: () => widget.onDone(
                  _feeling ?? CheckInFeeling.calm,
                  _stress.round(),
                  _practice ?? PracticeChoice.grounding,
                  length,
                ),
              ),
              if (length != PracticeLength.values.last) Gap.s,
            ],
          ],
        ),
      ),
    };
    return MotionSwitcher(
      child: KeyedSubtree(key: ValueKey(_step), child: content),
    );
  }
}

/// Beat 9 — câu hỏi mở để mang tới buổi khám.
class QuestionPrompt extends StatefulWidget {
  const QuestionPrompt({super.key, required this.onAnswer, this.onSkip});

  final ValueChanged<String> onAnswer;
  final VoidCallback? onSkip;

  @override
  State<QuestionPrompt> createState() => _QuestionPromptState();
}

class _QuestionPromptState extends State<QuestionPrompt> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PromptCard(
      title: context.l10n.questionTitle,
      subtitle: context.l10n.questionSubtitle,
      onSkip: widget.onSkip,
      child: Column(
        children: [
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: context.l10n.questionLabel,
              hintText: context.l10n.questionHint,
            ),
          ),
          Gap.m,
          FilledButton(
            onPressed: () => widget.onAnswer(_controller.text.trim()),
            child: Text(context.l10n.questionSave),
          ),
        ],
      ),
    );
  }
}

/// Beat 11 — ghi mood năm mức, đo lại căng thẳng và ghi cảm nhận.
class FeedbackPrompt extends StatefulWidget {
  const FeedbackPrompt({
    super.key,
    required this.onDone,
    required this.stressBefore,
  });

  final void Function(Mood? mood, int? stressAfter, String reflection) onDone;
  final int? stressBefore;

  @override
  State<FeedbackPrompt> createState() => _FeedbackPromptState();
}

class _FeedbackPromptState extends State<FeedbackPrompt> {
  late double _stress = (widget.stressBefore ?? 5).toDouble();
  Mood? _mood;
  int? _stressAfter;
  final _controller = TextEditingController();
  int _step = 0;

  void _next() => setState(() => _step++);

  void _finish([String reflection = '']) {
    widget.onDone(_mood, _stressAfter, reflection.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = switch (_step) {
      0 => PromptCard(
        title: l10n.feedbackMoodTitle,
        subtitle: l10n.feedbackMoodSubtitle,
        onSkip: _next,
        child: Column(
          children: [
            for (final mood in Mood.values) ...[
              ChoiceButton(
                label: mood.label(l10n),
                selected: _mood == mood,
                leading: Text(mood.emoji, style: const TextStyle(fontSize: 26)),
                onPressed: () => setState(() {
                  _mood = mood;
                  _step = 1;
                }),
              ),
              if (mood != Mood.values.last) Gap.s,
            ],
          ],
        ),
      ),
      1 => PromptCard(
        title: l10n.feedbackStressTitle,
        subtitle: widget.stressBefore != null
            ? l10n.feedbackStressStarted(widget.stressBefore!)
            : null,
        onSkip: _next,
        child: Column(
          children: [
            _StressSlider(
              value: _stress,
              onChanged: (v) => setState(() => _stress = v),
            ),
            Gap.l,
            FilledButton(
              onPressed: () => setState(() {
                _stressAfter = _stress.round();
                _step = 2;
              }),
              child: Text(l10n.commonContinue),
            ),
          ],
        ),
      ),
      _ => PromptCard(
        title: l10n.feedbackNoticeTitle,
        subtitle: l10n.feedbackNoticeSubtitle,
        onSkip: _finish,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.feedbackNoticeLabel,
                hintText: l10n.feedbackNoticeHint,
              ),
            ),
            Gap.m,
            FilledButton(
              onPressed: () => _finish(_controller.text),
              child: Text(l10n.commonContinue),
            ),
          ],
        ),
      ),
    };
    return MotionSwitcher(
      child: KeyedSubtree(key: ValueKey(_step), child: content),
    );
  }
}

/// Thang 0–10, hiện số to để người thị lực kém vẫn đọc được.
class _StressSlider extends StatelessWidget {
  const _StressSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '${value.round()}',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        Semantics(
          label: context.l10n.stressLevel,
          child: Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            label: '${value.round()}',
            semanticFormatterCallback: (value) =>
                context.l10n.stressOutOfTen(value.round()),
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.l10n.stressScaleLow,
                style: theme.textTheme.bodySmall,
              ),
            ),
            Gap.m,
            Expanded(
              child: Text(
                context.l10n.stressScaleHigh,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
