import 'dart:math';

import '../models/mood.dart';

/// Sinh câu hỏi gợi mở để người dùng dễ bắt đầu viết.
///
/// Bộ câu hỏi soạn sẵn, chạy hoàn toàn ngoại tuyến — không cần mạng, không
/// gửi nhật ký đi đâu. Nếu sau này muốn gợi ý do mô hình sinh ra, thay thân
/// [promptFor] bằng một lời gọi API bất đồng bộ và đổi kiểu trả về thành
/// `Future<String>`; phần UI gọi nó đã tách sẵn ở widget ReflectionCard nên
/// không phải sửa chỗ khác.
class ReflectionService {
  ReflectionService({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const _byMood = <Mood, List<String>>{
    Mood.awful: [
      'What feels heaviest right now? Try naming it.',
      'If a friend were in this situation, what would you say to them?',
      'Is there one small thing you could do now to lighten it a little?',
    ],
    Mood.low: [
      'What happened today that took something out of you?',
      'What is your body telling you — tired, hungry, short on sleep?',
      'Is there anything you are expecting of yourself that could wait?',
    ],
    Mood.neutral: [
      'What small detail of today is worth remembering?',
      'Where did most of your time go today?',
      'If tomorrow were just like today, what would you change?',
    ],
    Mood.good: [
      'What went smoothly today?',
      'Who helped make today feel easier?',
      'Which of your habits is actually working for you?',
    ],
    Mood.great: [
      'Which moment made the day?',
      'What would you like to keep from today for the harder days?',
      'What did you manage that surprised even you?',
    ],
  };

  /// Một câu hỏi ngẫu nhiên hợp với [mood].
  String promptFor(Mood mood) {
    final prompts = _byMood[mood] ?? _byMood[Mood.neutral]!;
    return prompts[_random.nextInt(prompts.length)];
  }

  /// Câu hỏi khác câu [previous], để nút đổi câu luôn có tác dụng.
  String anotherFor(Mood mood, String? previous) {
    final prompts = _byMood[mood] ?? _byMood[Mood.neutral]!;
    if (prompts.length == 1) return prompts.first;
    String next;
    do {
      next = prompts[_random.nextInt(prompts.length)];
    } while (next == previous);
    return next;
  }
}

/// Thẻ gợi ý sẵn có khi thêm nhật ký.
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
