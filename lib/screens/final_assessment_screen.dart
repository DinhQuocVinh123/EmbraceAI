import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../models/study_assessment.dart';
import '../services/study_assessment_service.dart';
import '../widgets/choice_tile.dart';
import '../widgets/language_picker.dart';
import '../widgets/step_actions.dart';

/// Phụ lục B–D, mỗi màn hình một câu hỏi.
///
/// Theo khuyến nghị ISPOR khi chuyển thang đo chuẩn (GAD-7) sang màn hình,
/// mỗi câu phải tự đầy đủ: câu dẫn gốc của thang đo nằm trên mọi màn của nhóm
/// câu đó, chữ giữ nguyên văn. Mỗi lần sang câu mới, câu trả lời được lưu nháp.
/// Bản tiếng Việt là bản dịch nháp; với GAD-7 phải thay bằng bản tiếng Việt đã
/// được kiểm định trước khi dùng với người tham gia thật. Câu trả lời lưu bằng
/// điểm, không phụ thuộc ngôn ngữ.
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
  static String _gadStem(AppLocalizations l) => l.gadStem;
  static List<String> _gadQuestions(AppLocalizations l) => [
    l.gad1,
    l.gad2,
    l.gad3,
    l.gad4,
    l.gad5,
    l.gad6,
    l.gad7,
  ];
  static Map<int, String> _gadOptions(AppLocalizations l) => {
    0: l.gadNotAtAll,
    1: l.gadSeveralDays,
    2: l.gadMoreThanHalf,
    3: l.gadNearlyEveryDay,
  };

  static Map<int, String> _wellbeingOptions(AppLocalizations l) => {
    1: l.wellbeingVeryPoor,
    2: l.wellbeingPoor,
    3: l.wellbeingFair,
    4: l.wellbeingGood,
    5: l.wellbeingVeryGood,
  };

  static List<String> _premQuestions(AppLocalizations l) => [
    l.prem1,
    l.prem2,
    l.prem3,
    l.prem4,
    l.prem5,
    l.prem6,
    l.prem7,
    l.prem8,
  ];
  static Map<int, String> _premOptions(AppLocalizations l) => {
    1: l.premStronglyDisagree,
    2: l.premDisagree,
    3: l.premNeutral,
    4: l.premAgree,
    5: l.premStronglyAgree,
  };

  static List<String> _openQuestions(AppLocalizations l) => [
    l.open1,
    l.open2,
    l.open3,
    l.open4,
  ];

  static const _gadCount = 7;
  static const _premCount = 8;
  static const _openCount = 4;

  /// GAD-7, câu cảm nhận chung, 8 câu trải nghiệm, 4 câu mở.
  static const _questionCount = _gadCount + 1 + _premCount + _openCount;

  final _openControllers = List.generate(
    _openCount,
    (_) => TextEditingController(),
  );
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.finalAppBar),
        actions: [
          const LanguageButton(),
          IconButton(
            tooltip: l10n.homeSignOut,
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
                    nextLabel: _onReview ? l10n.finalSubmit : l10n.commonNext,
                    nextIcon: _onReview
                        ? Icons.send_outlined
                        : Icons.arrow_forward,
                    onNext: _next,
                    backLabel: _page == 0 ? l10n.finalDoLater : l10n.commonBack,
                    onBack: _page == 0 ? _defer : _back,
                    busy: _saving,
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _questionContent(BuildContext context) {
    final l10n = context.l10n;
    const gad = _gadCount;
    const prem = _premCount;
    final page = _page;
    if (page < gad) {
      return _ratingPage(
        context,
        section: l10n.finalSectionWellbeing,
        stem: _gadStem(l10n),
        number: page + 1,
        question: _gadQuestions(l10n)[page],
        options: _gadOptions(l10n),
        value: _answers.gadResponses[page],
        onChanged: (value) => _answers.gadResponses[page] = value,
      );
    }
    if (page == gad) {
      return _ratingPage(
        context,
        section: l10n.finalSectionWellbeing,
        question: l10n.wellbeingQuestion,
        options: _wellbeingOptions(l10n),
        value: _answers.emotionalWellbeing,
        onChanged: (value) => _answers.emotionalWellbeing = value,
      );
    }
    if (page < gad + 1 + prem) {
      final index = page - gad - 1;
      return _ratingPage(
        context,
        section: l10n.finalSectionExperience,
        stem: l10n.premStem,
        number: index + 1,
        question: _premQuestions(l10n)[index],
        options: _premOptions(l10n),
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
        context.l10n.demoQuestionOf(_page + 1, _questionCount),
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
              context.l10n.demoOptionalNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (value != null)
            TextButton.icon(
              onPressed: () => choose(null),
              icon: const Icon(Icons.clear, size: 18),
              label: Text(context.l10n.finalClearAnswer),
            ),
        ],
      ),
    ];
  }

  List<Widget> _openPage(BuildContext context, int index) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return [
      ..._header(context, l10n.finalSectionOwnWords),
      Text(
        l10n.finalOpenIntro,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
      Gap.s,
      Semantics(
        header: true,
        child: Text(
          '${index + 1}. ${_openQuestions(l10n)[index]}',
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
        decoration: InputDecoration(hintText: l10n.finalOpenHint),
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
    final l10n = context.l10n;
    return [
      _Intro(title: l10n.finalReviewTitle, body: l10n.finalReviewBody),
      Gap.xl,
      _ReviewRow(
        icon: Icons.psychology_alt_outlined,
        label: l10n.finalReviewAnxiety,
        value: l10n.finalAnsweredOf(gadAnswered, _gadCount),
      ),
      const Divider(height: 32),
      _ReviewRow(
        icon: Icons.favorite_outline,
        label: l10n.finalSectionWellbeing,
        value: _answers.emotionalWellbeing == null
            ? l10n.demoNotAnswered
            : l10n.finalOutOfFive(_answers.emotionalWellbeing!),
      ),
      const Divider(height: 32),
      _ReviewRow(
        icon: Icons.fact_check_outlined,
        label: l10n.finalReviewExperience,
        value: l10n.finalAnsweredOf(premAnswered, _premCount),
      ),
      const Divider(height: 32),
      _ReviewRow(
        icon: Icons.notes_outlined,
        label: l10n.finalReviewWritten,
        value: l10n.finalAnsweredOf(openAnswered, _openCount),
      ),
      if (gad2 != null) ...[
        Gap.xl,
        Text(
          l10n.finalScreeningTotals,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Gap.s,
        Text(
          gad7 != null
              ? l10n.finalGadTotals(gad2, gad7)
              : l10n.finalGadIncomplete(gad2),
        ),
        Gap.xs,
        Text(
          l10n.finalScreeningNote,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.finalSaveFailed)));
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
