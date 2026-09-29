import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/motion.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import 'editor_screen.dart';

/// Xem đầy đủ một dòng nhật ký.
class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key, required this.initialEntry});

  final JournalEntry initialEntry;

  static Future<void> open(BuildContext context, JournalEntry entry) {
    final store = context.read<JournalStore>();
    return Navigator.of(context).push(
      AppMotion.pageRoute(
        context,
        builder: (_) => ChangeNotifierProvider.value(
          value: store,
          child: EntryDetailScreen(initialEntry: entry),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Đọc lại từ store theo id để màn hình tự cập nhật sau khi sửa.
    final currentEntry = context.select<JournalStore, JournalEntry?>(
      (store) => store.entries.where(_matchesInitialEntry).firstOrNull,
    );

    // Entry vừa bị xoá ở màn sửa — đóng luôn thay vì hiện dữ liệu cũ.
    final entry = currentEntry ?? initialEntry;
    final mood = entry.mood;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('d MMMM y', 'en').format(entry.createdAt)),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: currentEntry?.id == null
                ? null
                : () async {
                    final deleted = await EditorScreen.open(
                      context,
                      currentEntry,
                    );
                    if (deleted == true && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: mood == null
                        ? scheme.surfaceContainerHighest
                        : mood
                              .colorOn(theme.brightness)
                              .withValues(alpha: 0.22),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    mood?.emoji ?? '—',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                Gap.m,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mood?.label ?? 'Mood not recorded',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(entry.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Gap.l,
            if (entry.note.trim().isEmpty)
              Text(
                'That day you only logged a mood, with nothing written.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              SelectableText(
                entry.note,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            if (entry.tags.isNotEmpty) ...[
              Gap.l,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in entry.tags) Chip(label: Text(tag)),
                ],
              ),
            ],
            if (entry.updatedAt.difference(entry.createdAt).inMinutes > 1) ...[
              Gap.l,
              Text(
                'Last edited '
                '${DateFormat('d/M/y HH:mm').format(entry.updatedAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _matchesInitialEntry(JournalEntry entry) {
    final syncId = initialEntry.syncId;
    if (syncId != null) return entry.syncId == syncId;
    return initialEntry.id != null && entry.id == initialEntry.id;
  }
}
