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
        number: page + 1,
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
        // Một dãy số cho cả bảng, khớp với "Câu X / 20" ở trên.
        number: page + 1,
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
    required int number,
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
        child: Text('$number. $question', style: theme.textTheme.titleLarge),
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
          '${_page + 1}. ${_openQuestions(l10n)[index]}',
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

  /// Ba phần đúng tên và đúng thứ tự như lúc làm bài, kèm số câu, để người
  /// tham gia nhận ra ngay. Không hiện điểm sàng lọc GAD: người tham gia tự
  /// đọc điểm mà không ai giải thích thì dễ hoang mang; nhân viên vẫn xem được.
  List<Widget> _reviewContent(BuildContext context) {
    final l10n = context.l10n;
    final wellbeingAnswered =
        _answers.gadResponses.whereType<int>().length +
        (_answers.emotionalWellbeing == null ? 0 : 1);
    final premAnswered = _answers.premResponses.whereType<int>().length;
    final openAnswered = _openControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;
    const wellbeingCount = _gadCount + 1;
    const premStart = wellbeingCount;
    const openStart = premStart + _premCount;
    _ReviewRow row(
      IconData icon,
      String label,
      int start,
      int count,
      int answered,
    ) => _ReviewRow(
      icon: icon,
      label: label,
      value:
          '${l10n.finalReviewQuestions(start + 1, start + count)}'
          ' · ${l10n.finalAnsweredOf(answered, count)}',
      editLabel: l10n.entryEdit,
      onEdit: () => setState(() => _page = start),
    );
    return [
      _Intro(title: l10n.finalReviewTitle, body: l10n.finalReviewBody),
      Gap.xl,
      row(
        Icons.favorite_outline,
        l10n.finalSectionWellbeing,
        0,
        wellbeingCount,
        wellbeingAnswered,
      ),
      const Divider(height: 32),
      row(
        Icons.fact_check_outlined,
        l10n.finalSectionExperience,
        premStart,
        _premCount,
        premAnswered,
      ),
      const Divider(height: 32),
      row(
        Icons.notes_outlined,
        l10n.finalSectionOwnWords,
        openStart,
        _openCount,
        openAnswered,
      ),
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
    required this.editLabel,
    required this.onEdit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String editLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // Cột chữ giữ trọn chiều ngang; nút sửa nằm dưới, nên ở cỡ chữ 200% không
    // có gì bị chèn ép.
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
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(editLabel, semanticsLabel: '$editLabel: $label'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
