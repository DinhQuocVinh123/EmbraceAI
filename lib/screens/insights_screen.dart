import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/mood.dart';
import '../state/journal_store.dart';
import '../widgets/empty_state.dart';
import '../widgets/mood_distribution.dart';
import '../widgets/mood_trend_chart.dart';
import '../widgets/stat_tile.dart';

/// Tổng hợp: chuỗi ngày, xu hướng tâm trạng, phân bố, thẻ hay gặp.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<JournalStore>();

    if (store.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store.entries.isEmpty) {
      return const EmptyState(
        icon: Icons.insights_outlined,
        title: 'Chưa có gì để xem',
        message: 'Ghi vài ngày rồi quay lại — lúc đó xu hướng mới nói lên '
            'được điều gì đó.',
      );
    }

    final average = store.averageMood(days: 30);
    final tags = store.topTags();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Thống kê',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Gap.m,
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${store.streak}',
                  suffix: 'ngày',
                  label: 'Chuỗi liên tiếp',
                ),
              ),
              Gap.s,
              Expanded(
                child: StatTile(
                  value: '${store.entries.length}',
                  suffix: 'dòng',
                  label: 'Tổng đã ghi',
                ),
              ),
              Gap.s,
              Expanded(
                child: StatTile(
                  value: average == null ? '—' : average.toStringAsFixed(1),
                  suffix: average == null ? null : '/5',
                  label: 'TB 30 ngày',
                  accent:
                      average == null ? null : Mood.colorForAverage(average),
                ),
              ),
            ],
          ),
          Gap.m,
          _Section(
            title: 'Tâm trạng 14 ngày qua',
            subtitle: 'Chạm vào biểu đồ để xem từng ngày. '
                'Ngày không ghi để trống.',
            child: MoodTrendChart(data: store.dailyAverages(days: 14)),
          ),
          Gap.m,
          _Section(
            title: 'Bạn thường ở mức nào',
            child: MoodDistribution(counts: store.moodDistribution),
          ),
          if (tags.isNotEmpty) ...[
            Gap.m,
            _Section(
              title: 'Nhắc tới nhiều nhất',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags)
                    Chip(
                      label: Text('${tag.key}  ·  ${tag.value}'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              Gap.xs,
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            Gap.m,
            child,
          ],
        ),
      ),
    );
  }
}
