import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../l10n/source_names.dart';
import '../models/ask_result.dart';
import '../models/journal_entry.dart';
import '../services/ask_service.dart';
import '../state/journal_store.dart';

/// Hỏi đáp với Ask EmbraceAI (bản thử).
///
/// Mỗi câu hỏi là một lượt độc lập: trợ lý không nhớ câu trước, đúng phạm vi
/// của PoC. Câu trả lời chỉ đến từ tài liệu đã duyệt; câu khẩn cấp hiện thẻ
/// hướng dẫn cố định, không có chữ nào do AI viết.
class AskScreen extends StatefulWidget {
  const AskScreen({super.key, required this.service});

  final AskService service;

  static Future<void> open(BuildContext context, AskService service) {
    final store = context.read<JournalStore>();
    return Navigator.of(context).push(
      AppMotion.pageRoute(
        context,
        builder: (_) => ChangeNotifierProvider.value(
          value: store,
          child: AskScreen(service: service),
        ),
      ),
    );
  }

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _Exchange {
  _Exchange(this.question);

  final String question;

  /// Null trong lúc chờ máy chủ trả lời.
  AskResult? result;
  bool saved = false;
}

class _AskScreenState extends State<AskScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _exchanges = <_Exchange>[];

  bool get _waiting => _exchanges.isNotEmpty && _exchanges.last.result == null;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final question = (text ?? _controller.text).trim();
    if (question.isEmpty || _waiting) return;
    final exchange = _Exchange(question);
    final language = context.l10n.localeName;
    setState(() {
      _exchanges.add(exchange);
      _controller.clear();
    });
    _scrollToEnd();
    final result = await widget.service.ask(question, language: language);
    if (!mounted) return;
    setState(() => exchange.result = result);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (AppMotion.isReduced(context)) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: AppMotion.standard,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Câu hỏi y khoa được lưu vào nhật ký với thẻ Appointment, để người tham
  /// gia mang theo tới buổi khám. Chỉ lưu trên máy, như mọi mục tự viết.
  Future<void> _saveQuestion(_Exchange exchange) async {
    final now = DateTime.now();
    await context.read<JournalStore>().save(
      JournalEntry(
        mood: null,
        note: context.l10n.askAppointmentNote(exchange.question),
        tags: const ['Appointment'],
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    setState(() => exchange.saved = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.askTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _Intro(
                    examples: _exchanges.isEmpty
                        ? [
                            context.l10n.askExampleLength,
                            context.l10n.askExampleCaptions,
                            context.l10n.askExampleJournal,
                          ]
                        : const [],
                    onExample: _waiting ? null : (q) => _send(q),
                  ),
                  for (final exchange in _exchanges) ...[
                    Gap.l,
                    _QuestionBubble(text: exchange.question),
                    Gap.s,
                    if (exchange.result case final result?)
                      Semantics(
                        liveRegion: true,
                        child: _ResultCard(
                          result: result,
                          saved: exchange.saved,
                          onSave: () => _saveQuestion(exchange),
                        ),
                      )
                    else
                      const _Thinking(),
                  ],
                ],
              ),
            ),
            _Composer(
              controller: _controller,
              canSend: !_waiting,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.examples, required this.onExample});

  final List<String> examples;
  final ValueChanged<String>? onExample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.l10n.askIntroTitle,
            style: theme.textTheme.titleLarge,
          ),
        ),
        Gap.s,
        Text(
          context.l10n.askIntroBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (examples.isNotEmpty) ...[
          Gap.m,
          Text(
            context.l10n.askTryAsking,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Gap.s,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in examples)
                ActionChip(
                  label: Text(example),
                  onPressed: onExample == null
                      ? null
                      : () => onExample!(example),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _QuestionBubble extends StatelessWidget {
  const _QuestionBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Câu hỏi của người dùng nằm sát bên phải, chừa một khoảng bên trái để
    // phân biệt với câu trả lời.
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(width: 48),
        Flexible(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadius.lg,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                text,
                semanticsLabel: context.l10n.askYouAsked(text),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox.square(
          dimension: 20,
          child: AppMotion.isReduced(context)
              ? Icon(
                  Icons.hourglass_empty,
                  size: 20,
                  color: theme.colorScheme.primary,
                )
              : const CircularProgressIndicator(strokeWidth: 2),
        ),
        Gap.s,
        Text(
          context.l10n.askLooking,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.saved,
    required this.onSave,
  });

  final AskResult result;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (result.type == AskResultType.emergency) return const _EmergencyCard();

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final (icon, title, fallback) = switch (result.type) {
      AskResultType.answer => (Icons.chat_bubble_outline, null, ''),
      AskResultType.medicalRedirect => (
        Icons.medical_information_outlined,
        l10n.askMedicalTitle,
        l10n.askMedicalBody,
      ),
      AskResultType.outOfScope => (
        Icons.info_outline,
        null,
        l10n.askOutOfScope,
      ),
      AskResultType.notFound => (
        Icons.search_off,
        null,
        l10n.askNotFound,
      ),
      AskResultType.busy => (
        Icons.hourglass_empty,
        null,
        l10n.askBusy,
      ),
      AskResultType.error || AskResultType.emergency => (
        Icons.error_outline,
        null,
        l10n.askError,
      ),
    };
    // Ở ngôn ngữ khác tiếng Anh, chỉ câu trả lời thật mới dùng chữ của model.
    // Các trường hợp còn lại hiện câu soạn sẵn của app: ít chữ do AI tự viết
    // hơn, và câu báo bận hay lỗi của máy chủ vốn viết bằng tiếng Anh.
    final showsModelText =
        result.answer.isNotEmpty &&
        (l10n.localeName == 'en' || result.type == AskResultType.answer);
    final body = showsModelText ? result.answer : fallback;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                Gap.s,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null) ...[
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Gap.xs,
                      ],
                      Text(
                        body,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      if (result.alsoAsked) ...[
                        Gap.s,
                        Text(
                          l10n.askAlsoAsked,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (result.type == AskResultType.medicalRedirect) ...[
              Gap.m,
              if (saved)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    Gap.s,
                    Expanded(
                      child: Text(
                        l10n.askSaved,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                )
              else
                FilledButton.tonalIcon(
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(l10n.askSaveForAppointment),
                ),
            ],
            if (result.sources.isNotEmpty) ...[
              Gap.m,
              Text(
                l10n.askSources,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Gap.xs,
              for (final source in result.sources)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      Gap.s,
                      Expanded(
                        child: Text(
                          source.title.isEmpty
                              ? sourceName(source.heading, l10n.localeName)
                              : '${sourceName(source.heading, l10n.localeName)}'
                                    ' · ${sourceName(source.title, l10n.localeName)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (showsModelText && result.writtenByAi) ...[
              Gap.m,
              const _AiLabel(),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiLabel extends StatelessWidget {
  const _AiLabel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.auto_awesome_outlined,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        Gap.xs,
        Expanded(
          child: Text(
            context.l10n.askAiLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Nội dung cố định, không qua AI. Số khẩn cấp cụ thể chờ nhóm nghiên cứu
/// xác nhận nước của người tham gia.
class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: AppRadius.lg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.emergency_outlined, color: theme.colorScheme.error),
            Gap.s,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.askEmergencyTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap.xs,
                  Text(
                    context.l10n.askEmergencyBody,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: AskService.maxQuestionLength,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: context.l10n.askHint,
                  counterText: '',
                ),
              ),
            ),
            Gap.s,
            IconButton.filled(
              tooltip: context.l10n.askSend,
              onPressed: canSend ? onSend : null,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
