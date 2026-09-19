import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import 'editor_screen.dart';

/// Xem đầy đủ một dòng nhật ký.
class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final int entryId;

  static Future<void> open(BuildContext context, JournalEntry entry) {
    final id = entry.id;
    if (id == null) return Future.value();
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Đọc lại từ store theo id để màn hình tự cập nhật sau khi sửa.
    final entry = context.select<JournalStore, JournalEntry?>(
      (store) => store.entries.where((e) => e.id == entryId).firstOrNull,
    );

    // Entry vừa bị xoá ở màn sửa — đóng luôn thay vì hiện dữ liệu cũ.
    if (entry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('d MMMM, y', 'vi').format(entry.createdAt)),
        actions: [
          IconButton(
            tooltip: 'Sửa',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => EditorScreen.open(context, entry),
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
                    color: entry.mood.color.withValues(alpha: 0.22),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.mood.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                Gap.m,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.mood.label,
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
                'Hôm đó bạn chỉ ghi lại tâm trạng, không viết gì thêm.',
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
                'Sửa lần cuối '
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
}
