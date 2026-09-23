import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
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
        title: 'Could not open your journal',
        message: '${store.error}',
        action: FilledButton.tonal(
          onPressed: store.load,
          child: const Text('Try again'),
        ),
      );
    }

    if (store.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_outline,
        title: 'Nothing here yet',
        message:
            'Write a line about today. One sentence is enough — this '
            'is for looking back, not for writing well.',
        action: FilledButton(
          onPressed: () => EditorScreen.open(context),
          child: const Text('Write the first line'),
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
                      onTap: () => EntryDetailScreen.open(context, entry),
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
            _greeting(now ?? DateTime.now()),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap.xs,
          Text(
            store.hasCheckedInToday
                ? 'You have written ${store.todayEntries.length} '
                      '${store.todayEntries.length == 1 ? "entry" : "entries"} '
                      'today.'
                : 'How are you feeling today?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (streak > 1) ...[
            Gap.m,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
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
                    '$streak days in a row',
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

  String _greeting(DateTime currentTime) {
    final hour = currentTime.hour;
    if (hour < 11) return 'Good morning';
    if (hour < 14) return 'Good afternoon';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
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
        _label(date, now ?? DateTime.now()),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _label(DateTime date, DateTime currentTime) {
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE', 'en').format(date);
    return DateFormat('d MMMM y', 'en').format(date);
  }
}
