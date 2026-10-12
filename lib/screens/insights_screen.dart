import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';
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
    final l10n = context.l10n;

    if (store.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store.entries.isEmpty) {
      return EmptyState(
        icon: Icons.insights_outlined,
        title: l10n.insightsEmptyTitle,
        message: l10n.insightsEmptyBody,
      );
    }

    final average = store.averageMood(days: 30);
    final tags = store.topTags();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            l10n.homeTabInsights,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Gap.m,
          // Ba ô cao bằng nhau kể cả khi một nhãn xuống hai dòng.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatTile(
                    value: '${store.streak}',
                    suffix: l10n.insightsDays,
                    label: l10n.insightsStreak,
                  ),
                ),
                Gap.s,
                Expanded(
                  child: StatTile(
                    value: '${store.entries.length}',
                    suffix: l10n.insightsEntries,
                    label: l10n.insightsWritten,
                  ),
                ),
                Gap.s,
                Expanded(
                  child: StatTile(
                    value: average == null ? '—' : average.toStringAsFixed(1),
                    suffix: average == null ? null : '/5',
                    label: l10n.insightsAverage,
                    accent: average == null
                        ? null
                        : Mood.colorForAverage(
                            average,
                            Theme.of(context).brightness,
                          ),
                  ),
                ),
              ],
            ),
          ),
          Gap.m,
          _Section(
            title: l10n.insightsTrendTitle,
            subtitle: l10n.insightsTrendBody,
            child: MoodTrendChart(data: store.dailyAverages(days: 14)),
          ),
          Gap.m,
          _Section(
            title: l10n.insightsDistributionTitle,
            child: MoodDistribution(counts: store.moodDistribution),
          ),
          if (tags.isNotEmpty) ...[
            Gap.m,
            _Section(
              title: l10n.insightsTagsTitle,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags)
                    Chip(
                      label: Text(
                        '${tagLabel(l10n, tag.key)}  ·  ${tag.value}',
                      ),
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
  const _Section({required this.title, required this.child, this.subtitle});

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
