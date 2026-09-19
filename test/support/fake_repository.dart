import 'package:embrace_ai/data/journal_repository.dart';
import 'package:embrace_ai/models/journal_entry.dart';
import 'package:embrace_ai/models/mood.dart';

/// Repository giả, giữ dữ liệu trong bộ nhớ — không đụng tới SQLite.
class FakeRepository implements JournalRepository {
  FakeRepository([List<JournalEntry> seed = const []]) : _entries = [...seed];

  final List<JournalEntry> _entries;
  var _nextId = 100;

  @override
  Future<List<JournalEntry>> fetchAll() async =>
      [..._entries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<JournalEntry> insert(JournalEntry entry) async {
    final saved = entry.copyWith(id: _nextId++);
    _entries.add(saved);
    return saved;
  }

  @override
  Future<void> update(JournalEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) _entries[index] = entry;
  }

  @override
  Future<void> delete(int id) async => _entries.removeWhere((e) => e.id == id);
}

/// Entry mẫu, đặt vào [daysAgo] ngày trước lúc 12h trưa.
JournalEntry fakeEntry({
  required int id,
  required int daysAgo,
  Mood mood = Mood.neutral,
  List<String> tags = const [],
  String? note,
}) {
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, now.day, 12)
      .subtract(Duration(days: daysAgo));
  return JournalEntry(
    id: id,
    mood: mood,
    note: note ?? 'note $id',
    tags: tags,
    createdAt: date,
    updatedAt: date,
  );
}
