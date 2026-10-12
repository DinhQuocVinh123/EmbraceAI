import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';
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
    final l10n = context.l10n;
    final time = DateFormat.Hm(l10n.localeName).format(entry.createdAt);
    final mood = entry.mood;
    final note = entryNote(l10n, entry);
    final tags = [for (final tag in entry.tags) tagLabel(l10n, tag)];

    final semanticsLabel = [
      mood?.label(l10n) ?? l10n.moodNotRecorded,
      time,
      if (note.trim().isNotEmpty) note.trim(),
      if (tags.isNotEmpty) l10n.entryTags(tags.join(', ')),
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
            borderRadius: AppRadius.lg,
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
                              mood?.label(l10n) ?? l10n.moodNotRecorded,
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
                        if (note.trim().isNotEmpty) ...[
                          Gap.xs,
                          Text(
                            note.trim(),
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
                              for (final tag in tags) _TagPill(label: tag),
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
        borderRadius: AppRadius.sm,
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
