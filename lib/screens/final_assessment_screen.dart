import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/study_assessment.dart';
import '../services/study_assessment_service.dart';
import '../widgets/choice_tile.dart';
import '../widgets/step_actions.dart';

/// Phụ lục B–D, mỗi màn hình một câu hỏi.
///
/// Theo khuyến nghị ISPOR khi chuyển thang đo chuẩn (GAD-7) sang màn hình,
/// mỗi câu phải tự đầy đủ: câu dẫn gốc của thang đo nằm trên mọi màn của nhóm
/// câu đó, chữ giữ nguyên văn. Mỗi lần sang câu mới, câu trả lời được lưu nháp.
class FinalAssessmentScreen extends StatefulWidget {
  const FinalAssessmentScreen({
    super.key,
    required this.service,
    required this.onSubmitted,
    required this.onDefer,
    required this.onSignOut,
  });

  final StudyAssessmentService service;
  final Future<void> Function() onSubmitted;
  final VoidCallback onDefer;
  final Future<void> Function() onSignOut;

  @override
  State<FinalAssessmentScreen> createState() => _FinalAssessmentScreenState();
}

class _FinalAssessmentScreenState extends State<FinalAssessmentScreen> {
  static const _gadStem =
      'Over the last 2 weeks, how often have you been bothered by the '
      'following problems?';
  static const _gadQuestions = [
    'Feeling nervous, anxious, or on edge',
    'Difficulty controlling worrying',
    'Worrying too much about different things',
    'Difficulty relaxing',
    'Restlessness / difficulty sitting still',
    'Becoming easily annoyed or irritable',
    'Feeling afraid as if something awful might happen',
  ];
  static const _gadOptions = {
    0: 'Not at all',
    1: 'Several days',
    2: 'More than half the days',
    3: 'Nearly every day',
  };

  static const _wellbeingQuestion =
      'How would you rate your overall emotional well-being right now?';
  static const _wellbeingOptions = {
    1: 'Very poor',
    2: 'Poor',
    3: 'Fair',
    4: 'Good',
    5: 'Very good',
  };

  static const _premStem = 'Please indicate how much you agree or disagree.';
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
  static const _premOptions = {
    1: 'Strongly disagree',
    2: 'Disagree',
    3: 'Neutral',
    4: 'Agree',
    5: 'Strongly agree',
  };

  static const _openQuestions = [
    'What did you like most about the experience?',
    'What did you find difficult or uncomfortable, if anything?',
    'How could the system be improved?',
    'Would you use this system again? Please explain why or why not.',
  ];

  /// GAD-7, câu cảm nhận chung, 8 câu trải nghiệm, 4 câu mở.
  static final _questionCount =
      _gadQuestions.length + 1 + _premQuestions.length + _openQuestions.length;

  final _openControllers = List.generate(4, (_) => TextEditingController());
  ProgramAssessmentAnswers _answers = ProgramAssessmentAnswers();

  /// Câu đang hiện; bằng số câu hỏi nghĩa là trang xem lại.
  int _page = 0;
  bool _loading = true;
  bool _saving = false;

  /// Các lần lưu nháp chạy nối tiếp nhau; lần gửi chính thức chờ chúng xong.
  Future<void> _drafts = Future.value();

  bool get _onReview => _page == _questionCount;

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
                  LinearProgressIndicator(
                    value: (_page + 1) / (_questionCount + 1),
                  ),
                  Expanded(
                    child: ListView(
                      key: ValueKey(_page),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      children: _onReview
                          ? _reviewContent(context)
                          : _questionContent(context),
                    ),
                  ),
                  StepActions(
                    nextLabel: _onReview ? 'Submit' : 'Next',
                    nextIcon: _onReview
                        ? Icons.send_outlined
                        : Icons.arrow_forward,
                    onNext: _next,
                    backLabel: _page == 0 ? 'Do this later' : 'Back',
                    onBack: _page == 0 ? _defer : _back,
                    busy: _saving,
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _questionContent(BuildContext context) {
    final gad = _gadQuestions.length;
    final prem = _premQuestions.length;
    final page = _page;
    if (page < gad) {
      return _ratingPage(
        context,
        section: 'Emotional well-being',
        stem: _gadStem,
        number: page + 1,
        question: _gadQuestions[page],
        options: _gadOptions,
        value: _answers.gadResponses[page],
        onChanged: (value) => _answers.gadResponses[page] = value,
      );
    }
    if (page == gad) {
      return _ratingPage(
        context,
        section: 'Emotional well-being',
        question: _wellbeingQuestion,
        options: _wellbeingOptions,
        value: _answers.emotionalWellbeing,
        onChanged: (value) => _answers.emotionalWellbeing = value,
      );
    }
    if (page < gad + 1 + prem) {
      final index = page - gad - 1;
      return _ratingPage(
        context,
        section: 'Your experience',
        stem: _premStem,
        number: index + 1,
        question: _premQuestions[index],
        options: _premOptions,
        value: _answers.premResponses[index],
        onChanged: (value) => _answers.premResponses[index] = value,
      );
    }
    return _openPage(context, page - gad - 1 - prem);
  }

  List<Widget> _header(BuildContext context, String section) {
    final theme = Theme.of(context);
    return [
      Text(
        'Question ${_page + 1} of $_questionCount',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      Gap.xs,
      Text(
        section,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      Gap.m,
    ];
  }

  List<Widget> _ratingPage(
    BuildContext context, {
    required String section,
    String? stem,
    int? number,
    required String question,
    required Map<int, String> options,
    required int? value,
    required void Function(int? value) onChanged,
  }) {
    final theme = Theme.of(context);
    void choose(int? choice) => setState(() => onChanged(choice));
    return [
      ..._header(context, section),
      if (stem != null) ...[
        Text(
          stem,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        Gap.s,
      ],
      Semantics(
        header: true,
        child: Text(
          number == null ? question : '$number. $question',
          style: theme.textTheme.titleLarge,
        ),
      ),
      Gap.m,
      for (final option in options.entries) ...[
        ChoiceTile(
          label: option.value,
          score: option.key,
          selected: value == option.key,
          onTap: () => choose(option.key),
        ),
        Gap.s,
      ],
      Row(
        children: [
          Expanded(
            child: Text(
              'This question is optional.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (value != null)
            TextButton.icon(
              onPressed: () => choose(null),
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear answer'),
            ),
        ],
      ),
    ];
  }

  List<Widget> _openPage(BuildContext context, int index) {
    final theme = Theme.of(context);
    return [
      ..._header(context, 'In your own words'),
      Text(
        'You may leave this blank. Please do not include your name or '
        'contact details.',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
      Gap.s,
      Semantics(
        header: true,
        child: Text(
          '${index + 1}. ${_openQuestions[index]}',
          style: theme.textTheme.titleLarge,
        ),
      ),
      Gap.m,
      TextField(
        controller: _openControllers[index],
        minLines: 4,
        maxLines: 10,
        maxLength: 2000,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Your answer (optional)'),
      ),
    ];
  }

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

  void _back() => setState(() => _page--);

  /// "Làm sau" vẫn giữ câu trả lời của câu đầu tiên.
  void _defer() {
    _saveDraft();
    widget.onDefer();
  }

  void _saveDraft() {
    _syncOpenResponses();
    _drafts = _drafts
        .then((_) => widget.service.saveAssessment(_answers, submit: false))
        .catchError((Object _) {});
  }

  Future<void> _next() async {
    if (!_onReview) {
      _saveDraft();
      setState(() => _page++);
      return;
    }
    _syncOpenResponses();
    setState(() => _saving = true);
    try {
      await _drafts;
      await widget.service.saveAssessment(_answers, submit: true);
      await widget.onSubmitted();
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
