import 'dart:async';

import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../models/appointment_question.dart';
import '../services/appointment_service.dart';
import '../widgets/appointment_prep_flow.dart';

/// "Câu hỏi cho buổi khám": tối đa 3 câu người tham gia muốn mang tới buổi
/// khám, xếp theo thứ tự muốn hỏi trước (biên bản họp, mục 2). Mở từ Ask
/// EmbraceAI; câu lưu ở cuối buổi tập cũng nằm ở đây.
class AppointmentQuestionsScreen extends StatefulWidget {
  const AppointmentQuestionsScreen({super.key, required this.service});

  final AppointmentService service;

  static Future<void> open(BuildContext context, AppointmentService service) {
    return Navigator.of(context).push(
      AppMotion.pageRoute(
        context,
        builder: (_) => AppointmentQuestionsScreen(service: service),
      ),
    );
  }

  @override
  State<AppointmentQuestionsScreen> createState() =>
      _AppointmentQuestionsScreenState();
}

class _AppointmentQuestionsScreenState
    extends State<AppointmentQuestionsScreen> {
  List<AppointmentQuestion>? _questions;
  bool _failed = false;

  /// Đang lưu một thay đổi: mọi nút khoá lại, để hai lần lưu không chồng lên
  /// nhau làm lộn thứ tự.
  bool _busy = false;

  /// Câu vừa được chuyển chỗ, tô sáng một lúc để người dùng thấy nó đi đâu.
  String? _highlight;
  Timer? _highlightTimer;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final questions = await widget.service.load();
      if (mounted) {
        setState(() {
          _questions = questions;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Chạy một thay đổi; lỗi mạng thì báo và tải lại cho đúng với máy chủ.
  Future<void> _change(Future<void> Function() action, {String? done}) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await action();
      if (done != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(done)));
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.appointmentSaveFailed)),
      );
    }
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _move(int from, int to) async {
    if (_busy) return;
    final list = [...?_questions];
    final moved = list.removeAt(from);
    list.insert(to, moved);
    _highlightTimer?.cancel();
    setState(() {
      _questions = list;
      _highlight = moved.id;
    });
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlight = null);
    });
    await _change(
      () => widget.service.reorder(list),
      done: context.l10n.appointmentMoved(to + 1),
    );
  }

  Future<void> _edit(AppointmentQuestion question) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _EditDialog(initial: question.question),
    );
    if (text == null || text.trim().isEmpty || text == question.question) {
      return;
    }
    await _change(() => widget.service.update(question.id, text));
  }

  /// Xoá là không lấy lại được, nên hỏi lại và nhắc đúng câu sắp xoá.
  Future<void> _remove(AppointmentQuestion question) async {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.appointmentRemoveTitle),
        content: Text(question.question),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.appointmentDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _change(
      () => widget.service.remove(question.id),
      done: l10n.appointmentDeleted,
    );
  }

  Future<void> _add() async {
    await Navigator.of(context).push(
      AppMotion.pageRoute(
        context,
        builder: (_) => _PrepPage(service: widget.service),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final questions = _questions;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appointmentListTitle)),
      body: SafeArea(
        child: Column(
          children: [
            // Giữ chỗ cố định để danh sách không nhảy khi thanh chờ hiện ra.
            SizedBox(
              height: 4,
              child: _busy ? const LinearProgressIndicator() : null,
            ),
            Expanded(child: _list(context, questions)),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<AppointmentQuestion>? questions) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      // Nhiều nhất 3 câu: dựng hết một lần, không cần danh sách lười.
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.appointmentListIntro,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          Gap.l,
          if (questions != null && questions.isNotEmpty) ...[
            Text(
              l10n.appointmentCount(
                questions.length,
                AppointmentService.maxQuestions,
              ),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.s,
          ],
          if (_failed)
            Text(l10n.appointmentLoadFailed)
          else if (questions == null)
            const Center(child: CircularProgressIndicator())
          else if (questions.isEmpty)
            const _EmptyState()
          else
            for (final (index, question) in questions.indexed) ...[
              _QuestionCard(
                number: index + 1,
                question: question,
                enabled: !_busy,
                highlighted: question.id == _highlight,
                onUp: index == 0 ? null : () => _move(index, index - 1),
                onDown: index == questions.length - 1
                    ? null
                    : () => _move(index, index + 1),
                onEdit: () => _edit(question),
                onRemove: () => _remove(question),
              ),
              Gap.m,
            ],
          Gap.s,
          FilledButton.icon(
            onPressed:
                _busy ||
                    questions == null ||
                    questions.length >= AppointmentService.maxQuestions
                ? null
                : _add,
            icon: const Icon(Icons.add),
            label: Text(l10n.appointmentAdd),
          ),
          if (questions != null &&
              questions.length >= AppointmentService.maxQuestions) ...[
            Gap.s,
            Text(
              l10n.appointmentListFull,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hộp sửa một câu hỏi. Tự giữ ô nhập, để ô nhập chỉ bị huỷ khi hộp đã đóng
/// hẳn (huỷ sớm hơn thì hiệu ứng đóng hộp còn đang dùng nó).
class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.initial});

  final String initial;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.prepEdit),
      content: SizedBox(
        width: 480,
        child: TextField(
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          maxLength: AppointmentService.maxQuestionLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.prepEditLabel),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// Một câu hỏi trong danh sách. Nút đổi thứ tự có chữ ("Đưa lên"), không chỉ
/// là mũi tên, và chỉ hiện khi dùng được: câu đầu không có "Đưa lên".
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.enabled,
    required this.highlighted,
    required this.onUp,
    required this.onDown,
    required this.onEdit,
    required this.onRemove,
  });

  final int number;
  final AppointmentQuestion question;
  final bool enabled;
  final bool highlighted;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    VoidCallback? when(VoidCallback? action) => enabled ? action : null;
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.fast),
      decoration: BoxDecoration(
        color: highlighted
            ? Color.alphaBlend(
                scheme.primaryContainer.withValues(alpha: 0.4),
                scheme.surface,
              )
            : scheme.surface,
        border: Border.all(
          color: highlighted ? scheme.primary : scheme.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
        borderRadius: AppRadius.lg,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.appointmentNumber(number),
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Gap.xs,
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              question.question,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
          Gap.xs,
          // Đổi thứ tự một hàng, sửa/xoá một hàng: nút xoá không nằm sát nút
          // hay dùng, và có màu cảnh báo (kèm chữ, không chỉ dựa vào màu).
          if (onUp != null || onDown != null)
            Wrap(
              spacing: 8,
              children: [
                if (onUp != null)
                  TextButton.icon(
                    onPressed: when(onUp),
                    icon: const Icon(Icons.arrow_upward),
                    label: Text(l10n.appointmentMoveUp),
                  ),
                if (onDown != null)
                  TextButton.icon(
                    onPressed: when(onDown),
                    icon: const Icon(Icons.arrow_downward),
                    label: Text(l10n.appointmentMoveDown),
                  ),
              ],
            ),
          Divider(height: 8, color: scheme.outlineVariant),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: when(onEdit),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.prepEdit),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                onPressed: when(onRemove),
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.appointmentDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lúc chưa có câu nào: nói rõ chỗ này để làm gì, nút thêm câu ở ngay dưới.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          Gap.s,
          Text(
            l10n.appointmentListEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          Gap.xs,
          Text(
            l10n.appointmentEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ chuẩn bị câu hỏi mở như một trang riêng (từ danh sách câu hỏi).
class _PrepPage extends StatelessWidget {
  const _PrepPage({required this.service});

  final AppointmentService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appointmentAdd)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: AppointmentPrepFlow(
            service: service,
            onSkip: () => Navigator.pop(context),
            onFinished: (_) => Navigator.pop(context),
            frame:
                ({
                  required String title,
                  String? subtitle,
                  String? eyebrow,
                  required Widget child,
                  VoidCallback? onSkip,
                }) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Gap.xs,
                    ],
                    Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.titleLarge),
                    ),
                    if (subtitle != null) ...[
                      Gap.xs,
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                    Gap.l,
                    child,
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
