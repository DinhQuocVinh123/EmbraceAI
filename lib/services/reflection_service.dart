import 'dart:math';

import '../l10n/app_localizations.dart';
import '../models/mood.dart';

/// Sinh câu hỏi gợi mở để người dùng dễ bắt đầu viết.
///
/// Bộ câu hỏi soạn sẵn, chạy hoàn toàn ngoại tuyến — không cần mạng, không
/// gửi nhật ký đi đâu. Nếu sau này muốn gợi ý do mô hình sinh ra, thay thân
/// [text] bằng một lời gọi API bất đồng bộ; phần UI gọi nó đã tách sẵn ở
/// widget ReflectionCard nên không phải sửa chỗ khác.
class ReflectionService {
  ReflectionService({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Mỗi mức tâm trạng có ba câu.
  static const promptsPerMood = 3;

  /// Số thứ tự một câu ngẫu nhiên.
  int pick() => _random.nextInt(promptsPerMood);

  /// Số thứ tự một câu khác câu [previous], để nút đổi câu luôn có tác dụng.
  int another(int previous) {
    int next;
    do {
      next = _random.nextInt(promptsPerMood);
    } while (next == previous);
    return next;
  }

  /// Câu thứ [index] cho [mood], theo ngôn ngữ đang dùng.
  static String text(AppLocalizations l, Mood mood, int index) =>
      switch (mood) {
        Mood.awful => [l.reflectAwful1, l.reflectAwful2, l.reflectAwful3],
        Mood.low => [l.reflectLow1, l.reflectLow2, l.reflectLow3],
        Mood.neutral => [
          l.reflectNeutral1,
          l.reflectNeutral2,
          l.reflectNeutral3,
        ],
        Mood.good => [l.reflectGood1, l.reflectGood2, l.reflectGood3],
        Mood.great => [l.reflectGreat1, l.reflectGreat2, l.reflectGreat3],
      }[index];
}

/// Thẻ gợi ý sẵn có khi thêm nhật ký. Lưu bằng tiếng Anh như một mã; tên
/// hiển thị lấy qua `tagLabel` trong lib/l10n/labels.dart.
const kSuggestedTags = <String>[
  'Appointment',
  'Family',
  'Friends',
  'Health',
  'Work',
  'Rest',
  'Exercise',
  'Alone',
];
