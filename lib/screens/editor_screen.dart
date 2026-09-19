import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
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
      MaterialPageRoute(builder: (_) => EditorScreen(entry: entry)),
    );
  }

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final JournalEntry _original =
      widget.entry ?? JournalEntry.draft();
  late final TextEditingController _noteController =
      TextEditingController(text: _original.note);

  late Mood _mood = _original.mood;
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
          title: Text(_isEditing ? 'Sửa dòng nhật ký' : 'Hôm nay thế nào?'),
          actions: [
            if (_isEditing)
              IconButton(
                tooltip: 'Xoá',
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
              ReflectionCard(mood: _mood),
              Gap.m,
              TextField(
                controller: _noteController,
                minLines: 5,
                maxLines: 12,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Viết vài dòng… (có thể để trống)',
                ),
              ),
              Gap.l,
              Text(
                'Liên quan đến',
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
                child: Text(_isEditing ? 'Lưu thay đổi' : 'Lưu lại'),
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
        SnackBar(content: Text('Lưu không thành công: $e')),
      );
    }
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ những gì vừa viết?'),
        content: const Text('Nội dung chưa lưu sẽ mất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Viết tiếp'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bỏ'),
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
      builder: (context) => AlertDialog(
        title: const Text('Xoá dòng này?'),
        content: const Text('Không khôi phục lại được.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá'),
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
            DateFormat('EEEE, d/M/y • HH:mm', 'vi').format(value),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _pick(context),
          child: const Text('Đổi'),
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
      locale: const Locale('vi'),
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
