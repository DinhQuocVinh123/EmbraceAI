import 'package:flutter/foundation.dart';

import '../data/journal_repository.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';

/// Điểm trung bình của một ngày. [average] null nghĩa là ngày đó không ghi gì.
class DailyAverage {
  const DailyAverage(this.date, this.average);
  final DateTime date;
  final double? average;
}

/// Nguồn sự thật duy nhất cho dữ liệu nhật ký trong phiên chạy.
///
/// Giữ toàn bộ entry trong bộ nhớ: một cuốn nhật ký cá nhân hiếm khi vượt
/// vài nghìn dòng, nên thống kê tính trực tiếp thay vì truy vấn SQL riêng.
class JournalStore extends ChangeNotifier {
  JournalStore(this._repository);

  final JournalRepository _repository;

  List<JournalEntry> _entries = const [];
  bool _loading = true;
  Object? _error;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _loading;
  Object? get error => _error;
  bool get isEmpty => !_loading && _entries.isEmpty;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _repository.fetchAll();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(JournalEntry entry) async {
    final stamped = entry.copyWith(updatedAt: DateTime.now());
    if (stamped.id == null) {
      final saved = await _repository.insert(stamped);
      _entries = [saved, ..._entries];
    } else {
      await _repository.update(stamped);
      _entries = [for (final e in _entries) e.id == stamped.id ? stamped : e];
    }
    _sort();
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    _entries = _entries.where((e) => e.id != id).toList();
    notifyListeners();
  }

  void _sort() => _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // ---------------------------------------------------------------- thống kê

  /// Gom entry theo ngày, ngày mới nhất lên đầu.
  Map<DateTime, List<JournalEntry>> get groupedByDay {
    final grouped = <DateTime, List<JournalEntry>>{};
    for (final entry in _entries) {
      grouped.putIfAbsent(entry.day, () => []).add(entry);
    }
    return grouped;
  }

  List<JournalEntry> get todayEntries {
    final today = _dayOf(DateTime.now());
    return _entries.where((e) => e.day == today).toList();
  }

  bool get hasCheckedInToday => todayEntries.isNotEmpty;

  /// Số ngày ghi liên tiếp tính tới hôm nay.
  ///
  /// Chưa ghi hôm nay thì chuỗi vẫn được tính từ hôm qua — để người dùng
  /// không thấy chuỗi về 0 ngay lúc mở app buổi sáng.
  int get streak {
    if (_entries.isEmpty) return 0;
    final days = _entries.map((e) => e.day).toSet();
    final today = _dayOf(DateTime.now());
    var cursor = days.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) return 0;

    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Điểm tâm trạng trung bình trong [days] ngày gần nhất, null nếu chưa có gì.
  double? averageMood({int days = 30}) {
    final from = _dayOf(DateTime.now()).subtract(Duration(days: days - 1));
    final recent = _entries
        .where((e) => !e.day.isBefore(from) && e.mood != null)
        .toList();
    if (recent.isEmpty) return null;
    final total = recent.fold<int>(0, (sum, e) => sum + e.mood!.score);
    return total / recent.length;
  }

  /// Chuỗi điểm trung bình theo ngày, cũ -> mới, đủ [days] mốc kể cả ngày trống.
  List<DailyAverage> dailyAverages({int days = 14}) {
    final grouped = groupedByDay;
    final today = _dayOf(DateTime.now());
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final dayEntries = grouped[date]?.where((e) => e.mood != null).toList();
      if (dayEntries == null || dayEntries.isEmpty) {
        return DailyAverage(date, null);
      }
      final total = dayEntries.fold<int>(0, (sum, e) => sum + e.mood!.score);
      return DailyAverage(date, total / dayEntries.length);
    });
  }

  /// Số lần xuất hiện của từng mức tâm trạng, theo thứ tự enum.
  Map<Mood, int> get moodDistribution {
    final counts = {for (final mood in Mood.values) mood: 0};
    for (final entry in _entries) {
      final mood = entry.mood;
      if (mood != null) counts[mood] = counts[mood]! + 1;
    }
    return counts;
  }

  /// Các thẻ dùng nhiều nhất, tối đa [limit] thẻ.
  List<MapEntry<String, int>> topTags({int limit = 6}) {
    final counts = <String, int>{};
    for (final entry in _entries) {
      for (final tag in entry.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  static DateTime _dayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
