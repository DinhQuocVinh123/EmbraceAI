import '../models/journal_entry.dart';
import 'app_database.dart';

/// Lớp truy cập dữ liệu nhật ký. UI không chạm thẳng vào SQL.
class JournalRepository {
  JournalRepository(this._database);

  final AppDatabase _database;
  static const _table = 'entries';

  Future<List<JournalEntry>> fetchAll() async {
    final db = await _database.instance;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(JournalEntry.fromMap).toList();
  }

  /// Trả về entry đã gắn id do DB cấp.
  Future<JournalEntry> insert(JournalEntry entry) async {
    final db = await _database.instance;
    final id = await db.insert(_table, entry.toMap());
    return entry.copyWith(id: id);
  }

  Future<void> update(JournalEntry entry) async {
    assert(entry.id != null, 'Không thể cập nhật entry chưa có id');
    final db = await _database.instance;
    await db.update(
      _table,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _database.instance;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
