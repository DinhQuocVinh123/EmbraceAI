import 'package:embrace_ai/data/journal_repository.dart';
import 'package:embrace_ai/models/journal_entry.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:embrace_ai/state/journal_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_repository.dart';

void main() {
  group('JournalStore', () {
    test('load nạp dữ liệu và tắt cờ loading', () async {
      final store = JournalStore(
        FakeRepository([fakeEntry(id: 1, daysAgo: 0)]),
      );

      await store.load();

      expect(store.isLoading, isFalse);
      expect(store.entries, hasLength(1));
      expect(store.error, isNull);
    });

    test('save thêm entry mới vào đầu danh sách', () async {
      final store = JournalStore(FakeRepository());
      await store.load();

      await store.save(JournalEntry.draft(mood: Mood.great));

      expect(store.entries, hasLength(1));
      expect(store.entries.first.id, isNotNull);
      expect(store.entries.first.mood, Mood.great);
    });

    test('save cập nhật entry đã có thay vì nhân đôi', () async {
      final store = JournalStore(
        FakeRepository([fakeEntry(id: 1, daysAgo: 0, mood: Mood.low)]),
      );
      await store.load();

      await store.save(store.entries.first.copyWith(mood: Mood.great));

      expect(store.entries, hasLength(1));
      expect(store.entries.first.mood, Mood.great);
    });

    test('delete bỏ entry khỏi danh sách', () async {
      final store = JournalStore(
        FakeRepository([fakeEntry(id: 1, daysAgo: 0)]),
      );
      await store.load();

      await store.delete(1);

      expect(store.entries, isEmpty);
    });

    test('streak đếm các ngày liền nhau tính từ hôm nay', () async {
      final store = JournalStore(
        FakeRepository([
          fakeEntry(id: 1, daysAgo: 0),
          fakeEntry(id: 2, daysAgo: 1),
          fakeEntry(id: 3, daysAgo: 2),
          // Đứt ở ngày thứ 3, nên chuỗi dừng ở 3.
          fakeEntry(id: 4, daysAgo: 4),
        ]),
      );
      await store.load();

      expect(store.streak, 3);
    });

    test('chưa ghi hôm nay thì chuỗi vẫn tính từ hôm qua', () async {
      final store = JournalStore(
        FakeRepository([
          fakeEntry(id: 1, daysAgo: 1),
          fakeEntry(id: 2, daysAgo: 2),
        ]),
      );
      await store.load();

      expect(store.streak, 2);
    });

    test('streak bằng 0 khi lần ghi gần nhất đã quá cũ', () async {
      final store = JournalStore(
        FakeRepository([fakeEntry(id: 1, daysAgo: 5)]),
      );
      await store.load();

      expect(store.streak, 0);
    });

    test('averageMood lấy trung bình các entry trong khoảng', () async {
      final store = JournalStore(
        FakeRepository([
          fakeEntry(id: 1, daysAgo: 0, mood: Mood.great), // 5
          fakeEntry(id: 2, daysAgo: 1, mood: Mood.neutral), // 3
          fakeEntry(id: 3, daysAgo: 40, mood: Mood.awful), // ngoài 30 ngày
        ]),
      );
      await store.load();

      expect(store.averageMood(days: 30), 4.0);
    });

    test('averageMood trả null khi khoảng đó chưa ghi gì', () async {
      final store = JournalStore(
        FakeRepository([fakeEntry(id: 1, daysAgo: 40)]),
      );
      await store.load();

      expect(store.averageMood(days: 7), isNull);
    });

    test('thống kê mood bỏ qua entry không có đánh giá cuối buổi', () async {
      final store = JournalStore(
        FakeRepository([
          fakeEntry(id: 1, daysAgo: 0, mood: Mood.great),
          fakeEntry(id: 2, daysAgo: 0, mood: null),
        ]),
      );
      await store.load();

      expect(store.averageMood(days: 30), 5.0);
      expect(store.dailyAverages(days: 1).single.average, 5.0);
      expect(store.moodDistribution[Mood.great], 1);
      expect(store.moodDistribution.values.fold<int>(0, (a, b) => a + b), 1);
    });

    test('dailyAverages đủ số mốc, ngày trống là null', () async {
      final store = JournalStore(
        FakeRepository([
          fakeEntry(id: 1, daysAgo: 0, mood: Mood.great),
          fakeEntry(id: 2, daysAgo: 0, mood: Mood.good),
        ]),
      );
      await store.load();

      final series = store.dailyAverages(days: 7);

      expect(series, hasLength(7));
      expect(series.last.average, 4.5); // (5 + 4) / 2
      expect(series.first.average, isNull);
    });

    test('moodDistribution đếm đủ cả mức chưa dùng', () async {
      final store = JournalStore(
        FakeRepository([
          fakeEntry(id: 1, daysAgo: 0, mood: Mood.good),
          fakeEntry(id: 2, daysAgo: 1, mood: Mood.good),
        ]),
      );
      await store.load();

      expect(store.moodDistribution[Mood.good], 2);
      expect(store.moodDistribution[Mood.awful], 0);
      expect(store.moodDistribution.keys, hasLength(Mood.values.length));
    });

    test('topTags xếp theo số lần dùng, cắt theo limit', () async {
      final store = JournalStore(
        FakeRepository([
          fakeEntry(id: 1, daysAgo: 0, tags: ['Công việc', 'Gia đình']),
          fakeEntry(id: 2, daysAgo: 1, tags: ['Công việc']),
          fakeEntry(id: 3, daysAgo: 2, tags: ['Sức khỏe']),
        ]),
      );
      await store.load();

      final tags = store.topTags(limit: 2);

      expect(tags, hasLength(2));
      expect(tags.first.key, 'Công việc');
      expect(tags.first.value, 2);
    });

    test('hasCheckedInToday phản ánh đúng ngày hôm nay', () async {
      final store = JournalStore(
        FakeRepository([fakeEntry(id: 1, daysAgo: 1)]),
      );
      await store.load();
      expect(store.hasCheckedInToday, isFalse);

      await store.save(JournalEntry.draft());
      expect(store.hasCheckedInToday, isTrue);
    });
  });

  group('buổi tập không lưu vào nhật ký', () {
    test('vẫn được ghi nhận khi kho có máy chủ', () async {
      final repo = _RecordingRepository();
      final store = JournalStore(repo);
      final at = DateTime(2026, 9, 29, 9);

      await store.recordUnsavedSession(
        occurredAt: at,
        moodAfter: Mood.good,
        reflectionProvided: false,
      );

      expect(repo.recorded, [(at, Mood.good, false)]);
      // Không có mục nào được thêm vào nhật ký.
      expect(store.entries, isEmpty);
    });

    test('kho chỉ lưu trên máy thì bỏ qua, không báo lỗi', () async {
      final store = JournalStore(FakeRepository());
      await store.recordUnsavedSession(
        occurredAt: DateTime(2026, 9, 29),
        reflectionProvided: false,
      );
      expect(store.entries, isEmpty);
    });
  });
}

class _RecordingRepository extends FakeRepository implements SessionRecorder {
  final recorded = <(DateTime, Mood?, bool)>[];

  @override
  Future<void> recordUnsavedSession({
    required DateTime occurredAt,
    Mood? moodAfter,
    required bool reflectionProvided,
  }) async {
    recorded.add((occurredAt, moodAfter, reflectionProvided));
  }
}
