import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/mood.dart';

/// Số lần mỗi mức tâm trạng xuất hiện, dạng thanh ngang.
///
/// Thanh ngang thay vì cột đứng vì nhãn là chữ tiếng Việt có dấu — nằm ngang
/// thì đọc thẳng, không phải xoay đầu.
class MoodDistribution extends StatelessWidget {
  const MoodDistribution({super.key, required this.counts});

  final Map<Mood, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = counts.values.fold<int>(0, (sum, v) => sum + v);
    final max = counts.values.isEmpty
        ? 0
        : counts.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // Mức tốt lên trên cho thuận mắt, khớp với trục của biểu đồ đường.
        for (final mood in Mood.values.reversed) ...[
          _Row(
            mood: mood,
            count: counts[mood] ?? 0,
            max: max,
            total: total,
            labelStyle: theme.textTheme.bodySmall,
            trackColor: scheme.surfaceContainerHighest,
            mutedColor: scheme.onSurfaceVariant,
          ),
          if (mood != Mood.awful) Gap.s,
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.mood,
    required this.count,
    required this.max,
    required this.total,
    required this.labelStyle,
    required this.trackColor,
    required this.mutedColor,
  });

  final Mood mood;
  final int count;
  final int max;
  final int total;
  final TextStyle? labelStyle;
  final Color trackColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final fraction = max == 0 ? 0.0 : count / max;
    final percent = total == 0 ? 0 : (count * 100 / total).round();

    return Semantics(
      label: '${mood.label}: $count lần, $percent phần trăm',
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(mood.emoji, style: const TextStyle(fontSize: 18)),
          ),
          SizedBox(
            width: 92,
            child: Text(
              mood.label,
              style: labelStyle?.copyWith(color: mutedColor),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 10, color: trackColor),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(height: 10, color: mood.color),
                  ),
                ],
              ),
            ),
          ),
          Gap.s,
          SizedBox(
            width: 34,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: labelStyle?.copyWith(color: mutedColor),
            ),
          ),
        ],
      ),
    );
  }
}
