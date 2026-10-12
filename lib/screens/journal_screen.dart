import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../widgets/empty_state.dart';
import '../widgets/entry_card.dart';
import 'editor_screen.dart';
import 'entry_detail_screen.dart';

/// Danh sách nhật ký, gom theo ngày, mới nhất lên đầu.
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key, this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<JournalStore>();

    if (store.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store.error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: context.l10n.journalErrorTitle,
        message: '${store.error}',
        action: FilledButton.tonal(
          onPressed: store.load,
          child: Text(context.l10n.commonTryAgain),
        ),
      );
    }

    if (store.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_outline,
        title: context.l10n.journalEmptyTitle,
        message: context.l10n.journalEmptyBody,
        action: FilledButton(
          onPressed: () => EditorScreen.open(context),
          child: Text(context.l10n.journalEmptyAction),
        ),
      );
    }

    final items = _flatten(store.groupedByDay);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: store.load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(store: store, now: now),
            ),
            SliverPadding(
              // Chừa đáy cho nút nổi khỏi che dòng cuối.
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, index) =>
                    items[index + 1] is _DayHeaderItem ? Gap.l : Gap.s,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return switch (item) {
                    _DayHeaderItem(:final date) => _DayHeader(
                      date: date,
                      now: now,
                    ),
                    _EntryItem(:final entry) => EntryCard(
                      entry: entry,
                      onTap: entry.isRemoteSummary
                          ? null
                          : () => EntryDetailScreen.open(context, entry),
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trải map theo ngày thành danh sách phẳng để SliverList dựng một lần.
  List<_Item> _flatten(Map<DateTime, List<JournalEntry>> grouped) {
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final day in days) ...[
        _DayHeaderItem(day),
        for (final entry in grouped[day]!) _EntryItem(entry),
      ],
    ];
  }
}

sealed class _Item {
  const _Item();
}

class _DayHeaderItem extends _Item {
  const _DayHeaderItem(this.date);
  final DateTime date;
}

class _EntryItem extends _Item {
  const _EntryItem(this.entry);
  final JournalEntry entry;
}

class _Header extends StatelessWidget {
  const _Header({required this.store, this.now});

  final JournalStore store;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final streak = store.streak;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(context.l10n, now ?? DateTime.now()),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap.xs,
          Text(
            store.hasCheckedInToday
                ? context.l10n.journalTodayCount(store.todayEntries.length)
                : context.l10n.journalHowToday,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (streak > 1) ...[
            Gap.m,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: AppRadius.md,
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_outlined,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                  Gap.xs,
                  Text(
                    context.l10n.journalStreak(streak),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
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

  String _greeting(AppLocalizations l10n, DateTime currentTime) {
    final hour = currentTime.hour;
    if (hour < 11) return l10n.greetingMorning;
    if (hour < 18) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, this.now});

  final DateTime date;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        _label(context.l10n, date, now ?? DateTime.now()),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _label(AppLocalizations l10n, DateTime date, DateTime currentTime) {
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final diff = today.difference(date).inDays;
    if (diff == 0) return l10n.dayToday;
    if (diff == 1) return l10n.dayYesterday;
    if (diff < 7) return DateFormat('EEEE', l10n.localeName).format(date);
    return DateFormat('d MMMM y', l10n.localeName).format(date);
  }
}
