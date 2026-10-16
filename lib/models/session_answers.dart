import '../data/check_in_paths.dart';
import 'mood.dart';

/// Lựa chọn ở ô kiểm tra an toàn (Beat 2), đúng ba nhãn video đang dùng.
/// Tên hiển thị của các lựa chọn dưới đây nằm ở lib/l10n/labels.dart.
enum SafetyAnswer { yes, unsure, no }

/// Bài tập được chọn sau khi hỏi thăm — bước "AI tailoring" của Prof. Chang.
enum PracticeChoice { grounding, breathing }

/// How much uninterrupted practice the person wants before reflection.
enum PracticeLength { short, full }

/// Tất cả những gì người dùng trả lời trong một buổi.
///
/// Đây là dữ liệu cần cho cả hai việc: chọn bài phù hợp ngay trong buổi
/// (tailoring), và ghi lại để nhìn thấy thay đổi qua nhiều buổi (adherence).
class SessionAnswers {
  SafetyAnswer? safety;
  CheckInFeeling? feeling;

  /// Mức độ 0–10 của chính cảm xúc đã chọn (căng thẳng, mệt, khó tập trung...),
  /// trước và sau buổi tập. Xem lib/data/check_in_paths.dart.
  int? levelBefore;
  PracticeChoice? practice;
  PracticeLength? practiceLength;
  String? question;
  int? levelAfter;
  Mood? moodAfter;
  String? reflection;

  DateTime startedAt = DateTime.now();
  DateTime? finishedAt;

  /// Phần tập đã thật sự chạy. Dừng ở bước an toàn hay rời trước khi tập thì
  /// không tính là một buổi.
  bool practiceStarted = false;

  /// Mức đỡ hơn theo thang của cảm xúc đã chọn (dương là đỡ hơn), null nếu
  /// thiếu một trong hai lần đo. Thiếu cảm xúc thì coi như thang căng thẳng.
  int? get improvement => (levelBefore != null && levelAfter != null)
      ? (feeling ?? CheckInFeeling.stressed).path.improvement(
          levelBefore!,
          levelAfter!,
        )
      : null;
}
