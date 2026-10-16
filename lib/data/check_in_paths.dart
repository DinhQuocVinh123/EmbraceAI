import '../models/mood.dart';
import '../models/session_answers.dart';

/// Mỗi cảm xúc chọn ở bước check-in đi theo một nhánh riêng: câu hỏi đo mức độ
/// của chính cảm xúc đó (0–10), câu hỏi lại sau buổi tập, và bài tập gợi ý khi
/// cảm xúc đó mạnh. Chữ của từng nhánh nằm ở lib/l10n/labels.dart
/// (`CheckInFeelingText`) và trong các file ARB, khoá `checkIn<Cảm xúc>...`.
///
/// NỘI DUNG TẠM: nhóm nghiên cứu sẽ gửi bảng đề xuất câu hỏi và gợi ý cho từng
/// cảm xúc (biên bản họp, mục 1). Khi có bảng, sửa ở đây và trong ARB; luồng
/// trong lib/widgets/session_prompts.dart không phải đổi.
class CheckInPath {
  const CheckInPath({required this.higherIsBetter, this.strongSuggestion});

  /// Calm đo mức bình tâm nên điểm cao là tốt; các cảm xúc khác đo mức nặng
  /// nhẹ của cảm xúc khó chịu nên điểm thấp là tốt.
  final bool higherIsBetter;

  /// Bài gợi ý khi cảm xúc mạnh (từ [strongFrom] trở lên). null: không gợi ý.
  final PracticeChoice? strongSuggestion;

  /// Giống ngưỡng cũ của thang căng thẳng.
  static const strongFrom = 7;

  /// Mức thay đổi theo hướng tốt lên: dương là đỡ hơn, âm là nặng hơn.
  int improvement(int before, int after) =>
      higherIsBetter ? after - before : before - after;

  /// Bài gợi ý cho mức [level], hoặc null nếu không cần gợi ý.
  PracticeChoice? suggestionFor(int level) =>
      !higherIsBetter && level >= strongFrom ? strongSuggestion : null;
}

extension CheckInFeelingPath on CheckInFeeling {
  CheckInPath get path => switch (this) {
    CheckInFeeling.calm => const CheckInPath(higherIsBetter: true),
    CheckInFeeling.stressed => const CheckInPath(
      higherIsBetter: false,
      strongSuggestion: PracticeChoice.grounding,
    ),
    CheckInFeeling.tired => const CheckInPath(
      higherIsBetter: false,
      strongSuggestion: PracticeChoice.breathing,
    ),
    CheckInFeeling.upset => const CheckInPath(
      higherIsBetter: false,
      strongSuggestion: PracticeChoice.grounding,
    ),
    CheckInFeeling.distracted => const CheckInPath(
      higherIsBetter: false,
      strongSuggestion: PracticeChoice.grounding,
    ),
  };
}
