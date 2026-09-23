import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/motion.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../services/reflection_service.dart';
import '../state/journal_store.dart';
import '../widgets/mood_picker.dart';
import '../widgets/reflection_card.dart';

/// Màn hình thêm mới / sửa một dòng nhật ký.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, this.entry});

  /// Null nghĩa là tạo mới.
  final JournalEntry? entry;

  static Future<void> open(BuildContext context, [JournalEntry? entry]) {
    return Navigator.of(context).push(
      AppMotion.pageRoute(context, builder: (_) => EditorScreen(entry: entry)),
    );
  }

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final JournalEntry _original = widget.entry ?? JournalEntry.draft();
  late final TextEditingController _noteController = TextEditingController(
    text: _original.note,
  );

  late Mood? _mood = _original.mood;
  late final Set<String> _tags = _original.tags.toSet();
  late DateTime _createdAt = _original.createdAt;
  bool _saving = false;

  bool get _isEditing => widget.entry != null;

  bool get _isDirty =>
      _mood != _original.mood ||
      _noteController.text != _original.note ||
      !_sameTags(_tags, _original.tags.toSet()) ||
      _createdAt != _original.createdAt;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit entry' : 'How was today?'),
          actions: [
            if (_isEditing)
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              MoodPicker(
                selected: _mood,
                onChanged: (mood) => setState(() => _mood = mood),
              ),
              Gap.l,
              if (_mood case final mood?) ReflectionCard(mood: mood),
              Gap.m,
              TextField(
                controller: _noteController,
                minLines: 5,
                maxLines: 12,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Journal note',
                  hintText: 'Write a few lines… (you can leave this empty)',
                ),
              ),
              Gap.l,
              Text(
                'Related to',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Gap.s,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in _allTags)
                    FilterChip(
                      label: Text(tag),
                      selected: _tags.contains(tag),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _tags.add(tag);
                        } else {
                          _tags.remove(tag);
                        }
                      }),
                    ),
                ],
              ),
              Gap.l,
              _DateTimeRow(
                value: _createdAt,
                onChanged: (value) => setState(() => _createdAt = value),
              ),
              Gap.xl,
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_isEditing ? 'Save changes' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thẻ gợi ý, cộng thêm thẻ cũ của entry nếu nó không còn trong danh sách.
  List<String> get _allTags {
    final extras = _original.tags.where((t) => !kSuggestedTags.contains(t));
    return [...kSuggestedTags, ...extras];
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final store = context.read<JournalStore>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await store.save(
        _original.copyWith(
          mood: _mood,
          note: _noteController.text.trim(),
          tags: _tags.toList(),
          createdAt: _createdAt,
        ),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
        snackBarAnimationStyle: AppMotion.style(context),
      );
    }
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      animationStyle: AppMotion.style(context),
      builder: (context) => AlertDialog(
        title: const Text('Discard what you wrote?'),
        content: const Text('Anything unsaved will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep writing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmDelete() async {
    final id = widget.entry?.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: AppMotion.style(context),
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<JournalStore>().delete(id);
    if (!mounted) return;
    // Pop cả màn sửa lẫn màn chi tiết phía dưới nó.
    Navigator.of(context).pop();
  }

  static bool _sameTags(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

/// Cho phép ghi lùi ngày — nhật ký thường được viết muộn hơn lúc xảy ra.
class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        Gap.s,
        Expanded(
          child: Text(
            DateFormat('EEEE, d MMM y • HH:mm', 'en').format(value),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _pick(context),
          child: const Text('Change'),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      locale: const Locale('en'),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null) return;

    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}
