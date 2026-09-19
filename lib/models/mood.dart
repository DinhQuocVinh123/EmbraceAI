import 'package:flutter/material.dart';

/// Năm mức tâm trạng, chấm điểm 1..5.
///
/// Điểm số được lưu xuống DB (chứ không lưu tên enum) để sau này
/// thêm/bớt mức vẫn đọc được dữ liệu cũ.
enum Mood {
  awful(
    score: 1,
    label: 'Rất tệ',
    emoji: '😞',
    color: Color(0xFFE57373),
  ),
  low(
    score: 2,
    label: 'Không ổn',
    emoji: '😕',
    color: Color(0xFFFFB74D),
  ),
  neutral(
    score: 3,
    label: 'Bình thường',
    emoji: '😐',
    color: Color(0xFFFFD54F),
  ),
  good(
    score: 4,
    label: 'Khá ổn',
    emoji: '🙂',
    color: Color(0xFF81C784),
  ),
  great(
    score: 5,
    label: 'Tuyệt vời',
    emoji: '😄',
    color: Color(0xFF4DB6AC),
  );

  const Mood({
    required this.score,
    required this.label,
    required this.emoji,
    required this.color,
  });

  final int score;
  final String label;
  final String emoji;
  final Color color;

  /// Đọc từ DB. Điểm lạ (dữ liệu hỏng, phiên bản cũ) rơi về [neutral].
  static Mood fromScore(int score) => Mood.values.firstWhere(
        (mood) => mood.score == score,
        orElse: () => Mood.neutral,
      );

  /// Nội suy màu cho một điểm trung bình bất kỳ, ví dụ 3.4.
  static Color colorForAverage(double average) {
    final clamped = average.clamp(1.0, 5.0);
    final lower = Mood.fromScore(clamped.floor());
    final upper = Mood.fromScore(clamped.ceil());
    return Color.lerp(lower.color, upper.color, clamped - clamped.floor()) ??
        lower.color;
  }
}
