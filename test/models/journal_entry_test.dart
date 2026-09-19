import 'package:embrace_ai/models/journal_entry.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JournalEntry', () {
    final at = DateTime(2026, 3, 14, 21, 30);

    test('toMap/fromMap giữ nguyên nội dung', () {
      final entry = JournalEntry(
        id: 7,
        mood: Mood.good,
        note: 'Hôm nay ổn.',
        tags: const ['Công việc', 'Bạn bè'],
        createdAt: at,
        updatedAt: at,
      );

      final restored = JournalEntry.fromMap(entry.toMap());

      expect(restored.id, 7);
      expect(restored.mood, Mood.good);
      expect(restored.note, 'Hôm nay ổn.');
      expect(restored.tags, ['Công việc', 'Bạn bè']);
      expect(restored.createdAt, at);
    });

    test('entry không thẻ đọc lại thành danh sách rỗng', () {
      final entry = JournalEntry(
        mood: Mood.neutral,
        note: '',
        createdAt: at,
        updatedAt: at,
      );

      expect(JournalEntry.fromMap(entry.toMap()).tags, isEmpty);
    });

    test('toMap bỏ id khi chưa lưu, để SQLite tự cấp', () {
      final draft = JournalEntry.draft(at: at);
      expect(draft.toMap().containsKey('id'), isFalse);
    });

    test('day cắt bỏ giờ phút', () {
      final entry = JournalEntry.draft(at: at);
      expect(entry.day, DateTime(2026, 3, 14));
    });
  });

  group('Mood', () {
    test('fromScore trả về đúng mức', () {
      expect(Mood.fromScore(1), Mood.awful);
      expect(Mood.fromScore(5), Mood.great);
    });

    test('điểm ngoài khoảng rơi về neutral thay vì ném lỗi', () {
      expect(Mood.fromScore(0), Mood.neutral);
      expect(Mood.fromScore(99), Mood.neutral);
    });
  });
}
