import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../models/appointment_question.dart';
import '../services/appointment_service.dart';
import 'dictation_button.dart';
import 'emergency_notice.dart';
import 'session_prompts.dart' show ChoiceButton;

/// Khung bao từng bước: trong buổi tập là PromptCard, ở màn hình riêng là một
/// khối tiêu đề thường.
typedef PrepFrame =
    Widget Function({
      required String title,
      String? subtitle,
      String? eyebrow,
      required Widget child,
      VoidCallback? onSkip,
    });

/// Thẻ "chuẩn bị câu hỏi cho buổi khám" (biên bản họp, mục 2):
///
/// 1. Người tham gia kể điều muốn nhóm chăm sóc hiểu hoặc trao đổi.
/// 2. Chọn điều muốn hỏi (vì sao, nên theo dõi gì, làm gì nếu xảy ra lại, khác).
/// 3. AI tự host viết lại thành câu hỏi ngắn; người tham gia Lưu, Sửa hoặc Thử
///    cách viết khác. AI bận thì vẫn lưu được bằng lời của chính họ.
///
/// Đã đủ 3 câu thì thẻ chỉ nhắc lại 3 câu đó, cho đi tiếp hoặc thay một câu
/// (câu cũ chỉ bị xoá khi câu mới đã được lưu).
///
/// Lời có dấu hiệu khẩn cấp (máy chủ kiểm tra bằng danh sách từ) dừng thẻ và
/// hiện hướng dẫn tìm trợ giúp y tế; không có gì được lưu.
class AppointmentPrepFlow extends StatefulWidget {
  const AppointmentPrepFlow({
    super.key,
    required this.service,
    required this.frame,
    required this.onFinished,
    this.onSkip,
  });

  final AppointmentService service;
  final PrepFrame frame;

  /// Gọi khi xong: câu vừa lưu, hoặc null khi dừng vì khẩn cấp.
  final ValueChanged<AppointmentQuestion?> onFinished;

  /// Bỏ qua cả thẻ ở hai bước đầu.
  final VoidCallback? onSkip;

  @override
  State<AppointmentPrepFlow> createState() => _AppointmentPrepFlowState();
}

enum _Step { loading, full, concern, topics, working, result, emergency, saved }

class _AppointmentPrepFlowState extends State<AppointmentPrepFlow> {
  final _concern = TextEditingController();
  final _edit = TextEditingController();
  final _topics = <AppointmentTopic>{};
  _Step _step = _Step.loading;
  PrepOutcome? _outcome;
  bool _editing = false;
  bool _saving = false;
  int? _savedBefore;
  AppointmentQuestion? _saved;
  List<AppointmentQuestion> _existing = const [];

  /// Câu người tham gia chọn thay bằng câu mới (khi đã đủ 3 câu).
  AppointmentQuestion? _replacing;

  @override
  void initState() {
    super.initState();
    _concern.addListener(() => setState(() {}));
    widget.service.load().then(
      (list) {
        if (!mounted) return;
        setState(() {
          _existing = list;
          _savedBefore = list.length;
          _step = list.length >= AppointmentService.maxQuestions
              ? _Step.full
              : _Step.concern;
        });
      },
      onError: (_) {
        // Không tải được thì vẫn cho làm; lúc lưu sẽ báo nếu có lỗi.
        if (mounted) setState(() => _step = _Step.concern);
      },
    );
  }

  @override
  void dispose() {
    _concern.dispose();
    _edit.dispose();
    super.dispose();
  }

  bool get _full =>
      _replacing == null &&
      (_savedBefore ?? 0) >= AppointmentService.maxQuestions;

  Future<void> _rephrase({bool again = false}) async {
    final previous = again && _outcome == PrepOutcome.question
        ? _edit.text.trim()
        : null;
    setState(() {
      _step = _Step.working;
      _editing = false;
    });
    final result = await widget.service.rephrase(
      concern: _concern.text.trim(),
      topics: AppointmentTopic.values.where(_topics.contains).toList(),
      language: context.l10n.localeName,
      previous: previous,
    );
    if (!mounted) return;
    setState(() {
      _outcome = result.outcome;
      if (result.outcome == PrepOutcome.emergency) {
        _step = _Step.emergency;
        return;
      }
      // AI bận hoặc lỗi: đưa lời của chính người tham gia vào để họ vẫn lưu được.
      _edit.text = result.outcome == PrepOutcome.question
          ? result.text
          : _concern.text.trim();
      _step = _Step.result;
    });
  }

  Future<void> _save() async {
    final text = _edit.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      // Danh sách đã đủ: xoá câu được chọn thay trước, vì database không nhận
      // câu thứ tư. Câu mới đứng đúng chỗ câu cũ.
      final replacing = _replacing;
      if (replacing != null) await widget.service.remove(replacing.id);
      final saved = await widget.service.add(
        question: text.length > AppointmentService.maxQuestionLength
            ? text.substring(0, AppointmentService.maxQuestionLength)
            : text,
        concern: _concern.text.trim(),
        topics: AppointmentTopic.values.where(_topics.contains).toList(),
      );
      if (replacing != null) {
        final list = [...await widget.service.load()];
        final from = list.indexWhere((q) => q.id == saved.id);
        if (from >= 0) {
          final to = math.min(_existing.indexOf(replacing), list.length - 1);
          list.insert(math.max(to, 0), list.removeAt(from));
          await widget.service.reorder(list);
        }
      }
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _step = _Step.saved;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(context.l10n.appointmentSaveFailed)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final frame = widget.frame;
    final skip = widget.onSkip ?? () => widget.onFinished(null);
    final content = switch (_step) {
      _Step.loading => frame(
        title: l10n.prepConcernTitle,
        onSkip: widget.onSkip,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      _Step.full => frame(
        title: l10n.prepFullTitle,
        subtitle: l10n.prepFullBody,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, question) in _existing.indexed) ...[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appointmentNumber(index + 1),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Gap.xs,
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          question.question,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _replacing = question;
                          _step = _Step.concern;
                        }),
                        icon: const Icon(Icons.swap_horiz),
                        label: Text(l10n.prepReplace),
                      ),
                    ],
                  ),
                ),
              ),
              Gap.s,
            ],
            Gap.s,
            FilledButton(onPressed: skip, child: Text(l10n.commonContinue)),
          ],
        ),
      ),
      _Step.concern => frame(
        eyebrow: l10n.prepStep(1, 3),
        title: l10n.prepConcernTitle,
        subtitle: l10n.prepConcernSubtitle,
        onSkip: widget.onSkip,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_replacing case final replacing?) ...[
              Text(
                l10n.prepReplacing(replacing.question),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Gap.m,
            ],
            TextField(
              controller: _concern,
              minLines: 3,
              maxLines: 6,
              maxLength: AppointmentService.maxConcernLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.prepConcernLabel,
                hintText: l10n.prepConcernHint,
                suffixIcon: DictationButton.maybe(_concern),
              ),
            ),
            Gap.s,
            FilledButton(
              onPressed: _concern.text.trim().isEmpty
                  ? null
                  : () => setState(() => _step = _Step.topics),
              child: Text(l10n.commonContinue),
            ),
            if (_replacing != null)
              TextButton(
                onPressed: () => setState(() {
                  _replacing = null;
                  _step = _Step.full;
                }),
                child: Text(l10n.commonBack),
              ),
          ],
        ),
      ),
      _Step.topics => frame(
        eyebrow: l10n.prepStep(2, 3),
        title: l10n.prepTopicsTitle,
        subtitle: l10n.prepTopicsSubtitle,
        onSkip: widget.onSkip,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final topic in AppointmentTopic.values) ...[
              // Chọn được nhiều mục: ô đánh dấu, khác nút chọn một ở các thẻ khác.
              ChoiceButton(
                label: _topicLabel(l10n, topic),
                selected: _topics.contains(topic),
                showCheck: false,
                leading: Icon(
                  _topics.contains(topic)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: _topics.contains(topic)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => setState(() {
                  if (!_topics.remove(topic)) _topics.add(topic);
                }),
              ),
              Gap.s,
            ],
            Gap.s,
            FilledButton(
              onPressed: _topics.isEmpty ? null : _rephrase,
              child: Text(l10n.commonContinue),
            ),
            TextButton(
              onPressed: () => setState(() => _step = _Step.concern),
              child: Text(l10n.commonBack),
            ),
          ],
        ),
      ),
      _Step.working => frame(
        eyebrow: l10n.prepStep(3, 3),
        title: l10n.prepWorking,
        subtitle: l10n.prepWorkingBody,
        child: Semantics(
          liveRegion: true,
          label: l10n.prepWorking,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      _Step.result => frame(
        eyebrow: l10n.prepStep(3, 3),
        title: _outcome == PrepOutcome.question
            ? l10n.prepResultTitle
            : l10n.prepBusyTitle,
        subtitle: _outcome == PrepOutcome.question
            ? l10n.prepResultSubtitle
            : _outcome == PrepOutcome.busy
            ? l10n.prepBusyBody
            : l10n.prepErrorBody,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_editing)
              TextField(
                controller: _edit,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                maxLength: AppointmentService.maxQuestionLength,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.prepEditLabel,
                  suffixIcon: DictationButton.maybe(
                    _edit,
                    onChanged: () => setState(() {}),
                  ),
                ),
              )
            else
              Semantics(
                liveRegion: true,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _edit.text,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                ),
              ),
            Gap.s,
            Text(
              l10n.prepNotAdvice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_full) ...[
              Gap.s,
              Text(l10n.prepFull, style: theme.textTheme.bodyMedium),
            ],
            Gap.m,
            FilledButton.icon(
              onPressed: _full || _saving || _edit.text.trim().isEmpty
                  ? null
                  : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bookmark_add_outlined),
              label: Text(l10n.prepSave),
            ),
            Gap.s,
            OutlinedButton.icon(
              onPressed: () => setState(() => _editing = !_editing),
              icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
              label: Text(_editing ? l10n.prepEditDone : l10n.prepEdit),
            ),
            TextButton.icon(
              onPressed: () => _rephrase(again: true),
              icon: const Icon(Icons.refresh),
              label: Text(
                _outcome == PrepOutcome.question
                    ? l10n.prepAnotherWording
                    : l10n.commonTryAgain,
              ),
            ),
          ],
        ),
      ),
      _Step.emergency => frame(
        title: l10n.prepEmergencyTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: EmergencyNotice(extra: l10n.prepEmergencyAfter),
            ),
            Gap.m,
            FilledButton(
              onPressed: () => widget.onFinished(null),
              child: Text(l10n.commonContinue),
            ),
          ],
        ),
      ),
      _Step.saved => frame(
        title: l10n.prepSavedTitle,
        subtitle: l10n.prepSavedBody(
          math.min(
            (_savedBefore ?? 0) + (_replacing == null ? 1 : 0),
            AppointmentService.maxQuestions,
          ),
          AppointmentService.maxQuestions,
        ),
        child: FilledButton(
          onPressed: () => widget.onFinished(_saved),
          child: Text(l10n.commonDone),
        ),
      ),
    };
    return MotionSwitcher(
      child: KeyedSubtree(key: ValueKey(_step), child: content),
    );
  }
}

String _topicLabel(AppLocalizations l10n, AppointmentTopic topic) =>
    switch (topic) {
      AppointmentTopic.why => l10n.prepTopicWhy,
      AppointmentTopic.monitor => l10n.prepTopicMonitor,
      AppointmentTopic.nextTime => l10n.prepTopicNextTime,
      AppointmentTopic.other => l10n.prepTopicOther,
    };
