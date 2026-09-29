import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/study_assessment.dart';
import '../services/study_assessment_service.dart';

class FinalAssessmentScreen extends StatefulWidget {
  const FinalAssessmentScreen({
    super.key,
    required this.service,
    required this.onSubmitted,
    required this.onDefer,
    required this.onSignOut,
  });

  final StudyAssessmentService service;
  final VoidCallback onSubmitted;
  final VoidCallback onDefer;
  final Future<void> Function() onSignOut;

  @override
  State<FinalAssessmentScreen> createState() => _FinalAssessmentScreenState();
}

class _FinalAssessmentScreenState extends State<FinalAssessmentScreen> {
  static const _gadQuestions = [
    'Feeling nervous, anxious, or on edge',
    'Difficulty controlling worrying',
    'Worrying too much about different things',
    'Difficulty relaxing',
    'Restlessness / difficulty sitting still',
    'Becoming easily annoyed or irritable',
    'Feeling afraid as if something awful might happen',
  ];

  static const _premQuestions = [
    'The instructions were easy to understand.',
    'I felt comfortable using the system.',
    'The experience was calming and relaxing.',
    'The system was easy to interact with.',
    'I felt safe during the experience.',
    'The experience was helpful for my well-being.',
    'I would be willing to use this system again.',
    'Overall, I am satisfied with the experience.',
  ];

  static const _openQuestions = [
    'What did you like most about the experience?',
    'What did you find difficult or uncomfortable, if anything?',
    'How could the system be improved?',
    'Would you use this system again? Please explain why or why not.',
  ];

  final _openControllers = List.generate(4, (_) => TextEditingController());
  ProgramAssessmentAnswers _answers = ProgramAssessmentAnswers();
  int _step = 0;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final draft = await widget.service.loadAssessment('final');
      if (draft != null) {
        _answers = draft;
        for (var index = 0; index < _openControllers.length; index++) {
          _openControllers[index].text = draft.openResponses[index];
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _openControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final questionnaire'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  LinearProgressIndicator(value: (_step + 1) / 4),
                  Expanded(
                    child: ListView(
                      key: ValueKey(_step),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      children: [
                        Text(
                          'Step ${_step + 1} of 4',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Gap.s,
                        ..._stepContent(context),
                      ],
                    ),
                  ),
                  _BottomActions(
                    step: _step,
                    saving: _saving,
                    onBack: _step == 0 ? widget.onDefer : _back,
                    onNext: _saving ? null : _next,
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _stepContent(BuildContext context) => switch (_step) {
    0 => _promContent(context),
    1 => _premContent(context),
    2 => _openContent(context),
    _ => _reviewContent(context),
  };

  List<Widget> _promContent(BuildContext context) => [
    const _Intro(
      title: 'Emotional well-being',
      body:
          'Over the last 2 weeks, how often have you been bothered by the following problems? Every question on this page is optional.',
    ),
    Gap.l,
    for (var index = 0; index < _gadQuestions.length; index++) ...[
      _RatingQuestion(
        number: index + 1,
        question: _gadQuestions[index],
        value: _answers.gadResponses[index],
        options: const {
          0: 'Not at all',
          1: 'Several days',
          2: 'More than half the days',
          3: 'Nearly every day',
        },
        onChanged: (value) =>
            setState(() => _answers.gadResponses[index] = value),
      ),
      if (index != _gadQuestions.length - 1) const Divider(height: 32),
    ],
    Gap.xl,
    _RatingQuestion(
      question:
          'How would you rate your overall emotional well-being right now?',
      value: _answers.emotionalWellbeing,
      options: const {
        1: 'Very poor',
        2: 'Poor',
        3: 'Fair',
        4: 'Good',
        5: 'Very good',
      },
      onChanged: (value) => setState(() => _answers.emotionalWellbeing = value),
    ),
  ];

  List<Widget> _premContent(BuildContext context) => [
    const _Intro(
      title: 'Your experience',
      body:
          'Please indicate how much you agree or disagree. These questions are optional.',
    ),
    Gap.l,
    for (var index = 0; index < _premQuestions.length; index++) ...[
      _RatingQuestion(
        number: index + 1,
        question: _premQuestions[index],
        value: _answers.premResponses[index],
        options: const {
          1: 'Strongly disagree',
          2: 'Disagree',
          3: 'Neutral',
          4: 'Agree',
          5: 'Strongly agree',
        },
        onChanged: (value) =>
            setState(() => _answers.premResponses[index] = value),
      ),
      if (index != _premQuestions.length - 1) const Divider(height: 32),
    ],
  ];

  List<Widget> _openContent(BuildContext context) => [
    const _Intro(
      title: 'In your own words',
      body:
          'You may leave any of these questions blank. Please do not include your name or contact details.',
    ),
    Gap.l,
    for (var index = 0; index < _openQuestions.length; index++) ...[
      TextFormField(
        controller: _openControllers[index],
        minLines: 3,
        maxLines: 8,
        maxLength: 2000,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: '${index + 1}. ${_openQuestions[index]}',
          alignLabelWithHint: true,
        ),
      ),
      if (index != _openQuestions.length - 1) Gap.l,
    ],
  ];

  List<Widget> _reviewContent(BuildContext context) {
    final gadAnswered = _answers.gadResponses.whereType<int>().length;
    final premAnswered = _answers.premResponses.whereType<int>().length;
    final openAnswered = _openControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;
    final gad2 = _answers.gad2Score;
    final gad7 = _answers.gad7Score;
    return [
      const _Intro(
        title: 'Review and submit',
        body:
            'Your answers will be linked only to your study-issued Participant ID. You can go back and change them before submitting.',
      ),
      Gap.xl,
      _ReviewRow(
        icon: Icons.psychology_alt_outlined,
        label: 'Anxiety questions',
        value: '$gadAnswered of 7 answered',
      ),
      const Divider(height: 32),
      _ReviewRow(
        icon: Icons.favorite_outline,
        label: 'Emotional well-being',
        value: _answers.emotionalWellbeing == null
            ? 'Not answered'
            : '${_answers.emotionalWellbeing} of 5',
      ),
      const Divider(height: 32),
      _ReviewRow(
        icon: Icons.fact_check_outlined,
        label: 'Experience questions',
        value: '$premAnswered of 8 answered',
      ),
      const Divider(height: 32),
      _ReviewRow(
        icon: Icons.notes_outlined,
        label: 'Written feedback',
        value: '$openAnswered of 4 answered',
      ),
      if (gad2 != null) ...[
        Gap.xl,
        Text(
          'Recorded screening totals',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Gap.s,
        Text(
          gad7 != null
              ? 'GAD-2: $gad2/6  |  GAD-7: $gad7/21'
              : 'GAD-2: $gad2/6  |  GAD-7 incomplete',
        ),
        Gap.xs,
        Text(
          'These are screening scores, not a diagnosis.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ];
  }

  void _back() => setState(() => _step--);

  Future<void> _next() async {
    _syncOpenResponses();
    setState(() => _saving = true);
    try {
      if (_step < 3) {
        await widget.service.saveAssessment(_answers, submit: false);
        if (mounted) setState(() => _step++);
      } else {
        await widget.service.saveAssessment(_answers, submit: true);
        widget.onSubmitted();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your answers could not be saved. Try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _syncOpenResponses() {
    for (var index = 0; index < _openControllers.length; index++) {
      _answers.openResponses[index] = _openControllers[index].text.trim();
    }
  }
}

class _RatingQuestion extends StatelessWidget {
  const _RatingQuestion({
    this.number,
    required this.question,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final int? number;
  final String question;
  final int? value;
  final Map<int, String> options;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: number == null ? question : 'Question $number. $question',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number == null ? question : '$number. $question',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          Gap.s,
          for (final option in options.entries) ...[
            _RatingOption(
              score: option.key,
              label: option.value,
              selected: value == option.key,
              onTap: () => onChanged(option.key),
            ),
            if (option.key != options.keys.last) Gap.xs,
          ],
          if (value != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear answer'),
              ),
            ),
        ],
      ),
    );
  }
}

class _RatingOption extends StatelessWidget {
  const _RatingOption({
    required this.score,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int score;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$score, $label',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    Gap.s,
                    Text(
                      score.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Gap.s,
                    Expanded(child: Text(label)),
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

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.step,
    required this.saving,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final next = FilledButton.icon(
      onPressed: onNext,
      icon: saving
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(step == 3 ? Icons.send_outlined : Icons.arrow_forward),
      label: Text(step == 3 ? 'Submit' : 'Save and next'),
    );
    final back = OutlinedButton(
      onPressed: saving ? null : onBack,
      child: Text(step == 0 ? 'Do this later' : 'Back'),
    );
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: largeText
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: double.infinity, child: next),
                    Gap.s,
                    SizedBox(width: double.infinity, child: back),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: back),
                    Gap.m,
                    Expanded(child: next),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap.s,
        Text(
          body,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        Gap.m,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Gap.xs,
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}
