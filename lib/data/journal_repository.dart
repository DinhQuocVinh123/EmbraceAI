import '../models/journal_entry.dart';
import '../models/mood.dart';

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

/// Kho nào ghi được buổi tập lên máy chủ thì hiện thực thêm interface này.
///
/// Dùng cho buổi tập người dùng chọn không lưu vào nhật ký: buổi đó vẫn phải
/// được tính cho nghiên cứu (số buổi, lần hoạt động gần nhất, tâm trạng sau
/// buổi), chỉ là không có ghi chú nào rời khỏi máy.
abstract class SessionRecorder {
  Future<void> recordUnsavedSession({
    required DateTime occurredAt,
    Mood? moodAfter,
    required bool reflectionProvided,
  });
}
