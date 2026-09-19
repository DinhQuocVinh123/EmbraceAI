import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Mở và giữ kết nối SQLite. Toàn bộ dữ liệu nằm trên máy, không gửi đi đâu.
class AppDatabase {
  AppDatabase({this.fileName = 'embrace_ai.db'});

  final String fileName;
  static const _version = 1;

  Database? _db;

  Future<Database> get instance async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), fileName);
    return openDatabase(path, version: _version, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood INTEGER NOT NULL,
        note TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_entries_created_at ON entries (created_at DESC)',
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
