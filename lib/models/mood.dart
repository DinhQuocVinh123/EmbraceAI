import 'package:flutter/material.dart';

/// Năm mức tâm trạng dùng cho nhật ký, chấm điểm 1..5.
///
/// Điểm số được lưu xuống kho (chứ không lưu tên enum) để sau này thêm/bớt
/// mức vẫn đọc được dữ liệu cũ.
enum Mood {
  awful(
    score: 1,
    label: 'Really hard',
    emoji: '😞',
    onLight: Color(0xFFC62828),
    onDark: Color(0xFFE57373),
  ),
  low(
    score: 2,
    label: 'Not great',
    emoji: '😕',
    onLight: Color(0xFFC75100),
    onDark: Color(0xFFFFB74D),
  ),
  neutral(
    score: 3,
    label: 'Okay',
    emoji: '😐',
    // Vàng là mức giữa, nhưng vàng đủ đậm để đọc trên nền sáng thì lại ngả
    // sang nâu và lẫn với mức "Not great" ngay bên cạnh. Kéo về phía ô liu
    // cho hai mức tách hẳn nhau.
    onLight: Color(0xFF776C00),
    onDark: Color(0xFFFFEE9C),
  ),
  good(
    score: 4,
    label: 'Quite good',
    emoji: '🙂',
    onLight: Color(0xFF2E7D32),
    onDark: Color(0xFF81C784),
  ),
  great(
    score: 5,
    label: 'Really good',
    emoji: '😄',
    onLight: Color(0xFF00695C),
    onDark: Color(0xFF4DB6AC),
  );

  const Mood({
    required this.score,
    required this.label,
    required this.emoji,
    required this.onLight,
    required this.onDark,
  });

  final int score;
  final String label;
  final String emoji;

  /// Hai sắc độ cho cùng một ý nghĩa.
  ///
  /// Sắc nhạt kiểu Material 300 trông dịu trên nền tối, nhưng đặt lên nền sáng
  /// thì tụt xuống 1.3:1 — WCAG 2.2 đòi 3:1 cho hình khối mang thông tin, và
  /// người thị lực kém thì đơn giản là không thấy. Nên mỗi mức giữ hai sắc,
  /// [colorOn] chọn hộ.
  final Color onLight;
  final Color onDark;

  /// Đọc từ kho. Điểm lạ (dữ liệu hỏng, phiên bản cũ) rơi về [neutral].
  static Mood fromScore(int score) => Mood.values.firstWhere(
    (mood) => mood.score == score,
    orElse: () => Mood.neutral,
  );

  /// Màu hợp với nền đang dùng.
  Color colorOn(Brightness brightness) =>
      brightness == Brightness.dark ? onDark : onLight;

  /// Nội suy màu cho một điểm trung bình bất kỳ, ví dụ 3.4.
  static Color colorForAverage(double average, Brightness brightness) {
    final clamped = average.clamp(1.0, 5.0);
    final lower = Mood.fromScore(clamped.floor()).colorOn(brightness);
    final upper = Mood.fromScore(clamped.ceil()).colorOn(brightness);
    return Color.lerp(lower, upper, clamped - clamped.floor()) ?? lower;
  }
}

/// Trạng thái đầu buổi dùng để hiểu bối cảnh và hỗ trợ chọn bài tập.
///
/// Đây là các loại cảm nhận, không phải thang điểm tốt-xấu. Mood dùng cho
/// Journal và Insights được hỏi riêng bằng thang năm mức sau khi tập xong.
enum CheckInFeeling {
  calm('Calm', '🙂'),
  stressed('Stressed', '😟'),
  tired('Tired', '😪'),
  upset('Upset', '😣'),
  distracted('Distracted', '🤔');

  const CheckInFeeling(this.label, this.emoji);

  final String label;
  final String emoji;
}
