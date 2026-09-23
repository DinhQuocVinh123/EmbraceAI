import 'mood.dart';

/// Lựa chọn ở ô kiểm tra an toàn (Beat 2), đúng ba nhãn video đang dùng.
enum SafetyAnswer {
  yes('Yes, I can sit quietly'),
  unsure("I'm not sure"),
  no('Not right now');

  const SafetyAnswer(this.label);
  final String label;
}

/// Bài tập được chọn sau khi hỏi thăm — bước "AI tailoring" của Prof. Chang.
enum PracticeChoice {
  grounding(
    'Grounding',
    'Notice the support beneath you, then follow your breath',
  ),
  breathing('Follow the breath', 'Go straight to the breathing practice');

  const PracticeChoice(this.label, this.description);

  final String label;
  final String description;
}

/// How much uninterrupted practice the person wants before reflection.
enum PracticeLength {
  short('Short practice', 'About 3 minutes'),
  full('Full practice', 'About 5 to 6 minutes');

  const PracticeLength(this.label, this.description);

  final String label;
  final String description;
}

/// Tất cả những gì người dùng trả lời trong một buổi.
///
/// Đây là dữ liệu cần cho cả hai việc: chọn bài phù hợp ngay trong buổi
/// (tailoring), và ghi lại để nhìn thấy thay đổi qua nhiều buổi (adherence).
class SessionAnswers {
  SafetyAnswer? safety;
  CheckInFeeling? feeling;
  int? stressBefore;
  PracticeChoice? practice;
  PracticeLength? practiceLength;
  String? question;
  int? stressAfter;
  Mood? moodAfter;
  String? reflection;

  DateTime startedAt = DateTime.now();
  DateTime? finishedAt;

  /// Mức giảm căng thẳng, null nếu thiếu một trong hai lần đo.
  int? get stressDelta => (stressBefore != null && stressAfter != null)
      ? stressBefore! - stressAfter!
      : null;

  /// Câu phản hồi app đưa ra ở cuối buổi.
  ///
  /// Hiện sinh bằng luật, chạy ngoại tuyến, không gọi model nào. Đúng như
  /// Prof. Chang mô tả: nhắc lại điều người dùng vừa nói rồi gợi ý bước kế —
  /// vai trò hỗ trợ thực hành, không phải nhà trị liệu.
  String get closingMessage {
    final parts = <String>[];
    final delta = stressDelta;

    if (delta != null) {
      if (delta >= 3) {
        parts.add('Your stress went from $stressBefore down to $stressAfter.');
      } else if (delta > 0) {
        parts.add(
          'Your stress eased a little, from $stressBefore to '
          '$stressAfter.',
        );
      } else if (delta == 0) {
        parts.add(
          'Your stress stayed at $stressBefore. That happens — one '
          'session does not always shift things right away.',
        );
      } else {
        parts.add(
          'You feel more tense than when you started. Thank you for '
          'being honest about that.',
        );
      }
    }

    if (practice == PracticeChoice.grounding) {
      parts.add('Next time, a short body scan may suit you.');
    } else if (practice == PracticeChoice.breathing) {
      parts.add(
        'Next time, try adding the grounding part at the start and see '
        'whether it helps you settle.',
      );
    }

    if (question != null && question!.trim().isNotEmpty) {
      parts.add(
        'The question you wrote down has been saved for your next '
        'appointment.',
      );
    }

    if (parts.isEmpty) {
      parts.add('Thank you for making time for this practice.');
    }
    return parts.join(' ');
  }
}
