import '../models/journal_entry.dart';

/// Hợp đồng lưu trữ nhật ký.
///
/// `JournalStore` và toàn bộ UI chỉ biết tới interface này, nên đổi chỗ lưu
/// (SQLite, shared_preferences, server…) không ảnh hưởng gì tới phần còn lại.
abstract class JournalRepository {
  Future<List<JournalEntry>> fetchAll();

  /// Trả về entry đã gắn id do kho cấp.
  Future<JournalEntry> insert(JournalEntry entry);

  Future<void> update(JournalEntry entry);

  Future<void> delete(int id);
}
