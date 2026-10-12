import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../models/mood.dart';
import '../services/reflection_service.dart';

/// Câu hỏi gợi mở cho người dùng khi họ chưa biết viết gì.
///
/// Tự đổi câu khi tâm trạng được chọn lại, và có nút đổi câu thủ công.
class ReflectionCard extends StatefulWidget {
  const ReflectionCard({super.key, required this.mood});

  final Mood mood;

  @override
  State<ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends State<ReflectionCard> {
  final _service = ReflectionService();
  late int _prompt = _service.pick();

  @override
  void didUpdateWidget(covariant ReflectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      setState(() => _prompt = _service.pick());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final prompt = ReflectionService.text(
      context.l10n,
      widget.mood,
      _prompt,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: AppRadius.lg,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 20,
            color: scheme.onPrimaryContainer,
          ),
          Gap.s,
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.standard),
              child: Text(
                prompt,
                key: ValueKey(prompt),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  height: 1.4,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.reflectAnother,
            icon: const Icon(Icons.refresh, size: 20),
            color: scheme.onPrimaryContainer,
            onPressed: () => setState(
              () => _prompt = _service.another(_prompt),
            ),
          ),
        ],
      ),
    );
  }
}
