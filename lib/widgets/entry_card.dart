import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/journal_entry.dart';

/// Một dòng nhật ký trong danh sách.
class EntryCard extends StatelessWidget {
  const EntryCard({super.key, required this.entry, this.onTap});

  final JournalEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final time = DateFormat.Hm('en').format(entry.createdAt);
    final mood = entry.mood;

    final semanticsLabel = [
      mood?.label ?? 'Mood not recorded',
      time,
      if (entry.note.trim().isNotEmpty) entry.note.trim(),
      if (entry.tags.isNotEmpty) 'Tags: ${entry.tags.join(', ')}',
    ].join('. ');

    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticsLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
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
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  Gap.m,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              mood?.label ?? 'Mood not recorded',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              time,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (entry.note.trim().isNotEmpty) ...[
                          Gap.xs,
                          Text(
                            entry.note.trim(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (entry.tags.isNotEmpty) ...[
                          Gap.s,
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final tag in entry.tags)
                                _TagPill(label: tag),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
