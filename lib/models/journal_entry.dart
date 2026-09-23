import 'mood.dart';

/// Một lần ghi nhật ký: tâm trạng + ghi chú + thẻ.
class JournalEntry {
  const JournalEntry({
    this.id,
    required this.mood,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  final int? id;

  /// Null khi người dùng bỏ qua đánh giá mood cuối buổi.
  final Mood? mood;
  final String note;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Bản ghi mới, chưa có id cho tới khi DB cấp.
  factory JournalEntry.draft({Mood? mood = Mood.neutral, DateTime? at}) {
    final now = at ?? DateTime.now();
    return JournalEntry(mood: mood, note: '', createdAt: now, updatedAt: now);
  }

  JournalEntry copyWith({
    int? id,
    Mood? mood,
    String? note,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Ngày (bỏ giờ phút) — dùng để gom nhóm theo ngày.
  DateTime get day => DateTime(createdAt.year, createdAt.month, createdAt.day);

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'mood': mood?.score,
    'note': note,
    // Thẻ nối bằng '|' vì bản thân thẻ không cho chứa ký tự này.
    'tags': tags.join('|'),
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory JournalEntry.fromMap(Map<String, Object?> map) {
    final rawTags = (map['tags'] as String?) ?? '';
    return JournalEntry(
      id: map['id'] as int?,
      mood: switch (map['mood']) {
        final int score => Mood.fromScore(score),
        _ => null,
      },
      note: (map['note'] as String?) ?? '',
      tags: rawTags.isEmpty ? const [] : rawTags.split('|'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
