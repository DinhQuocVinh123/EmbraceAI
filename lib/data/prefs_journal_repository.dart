import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/journal_entry.dart';
import 'journal_repository.dart';

/// Lưu nhật ký dưới dạng JSON trong shared_preferences.
///
/// Chọn cách này thay cho SQLite vì app phải chạy được cả trên Android lẫn
/// web mobile — `sqflite` không có bản web. Một cuốn nhật ký cá nhân chỉ vài
/// chục KB nên đọc/ghi cả mảng một lần là đủ nhanh; nếu sau này dữ liệu lớn
/// hoặc cần đồng bộ nhiều máy thì thay bằng một lớp khác, interface giữ nguyên.
class PrefsJournalRepository implements JournalRepository {
  PrefsJournalRepository({SharedPreferences? prefs}) : _prefs = prefs;

  static const _entriesKey = 'journal.entries';
  static const _nextIdKey = 'journal.nextId';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<List<JournalEntry>> fetchAll() async {
    final prefs = await _store;
    final raw = prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final entries = decoded
        .map((e) => JournalEntry.fromMap(Map<String, Object?>.from(e as Map)))
        .toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  @override
  Future<JournalEntry> insert(JournalEntry entry) async {
    final prefs = await _store;
    final id = (prefs.getInt(_nextIdKey) ?? 1);
    final saved = entry.copyWith(id: id);
    final all = [...await fetchAll(), saved];
    await _write(prefs, all);
    await prefs.setInt(_nextIdKey, id + 1);
    return saved;
  }

  @override
  Future<void> update(JournalEntry entry) async {
    assert(entry.id != null, 'Không thể cập nhật entry chưa có id');
    final prefs = await _store;
    final all = [
      for (final e in await fetchAll()) e.id == entry.id ? entry : e,
    ];
    await _write(prefs, all);
  }

  @override
  Future<void> delete(int id) async {
    final prefs = await _store;
    final all = (await fetchAll()).where((e) => e.id != id).toList();
    await _write(prefs, all);
  }

  Future<void> _write(SharedPreferences prefs, List<JournalEntry> all) {
    return prefs.setString(
      _entriesKey,
      jsonEncode([for (final e in all) e.toMap()]),
    );
  }
}
