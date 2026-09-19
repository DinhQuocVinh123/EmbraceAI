import 'dart:math';

import '../models/mood.dart';

/// Sinh câu hỏi gợi mở để người dùng dễ bắt đầu viết.
///
/// Bộ câu hỏi soạn sẵn, chạy hoàn toàn ngoại tuyến — không cần mạng,
/// không gửi nhật ký đi đâu. Nếu sau này muốn gợi ý do mô hình sinh ra,
/// thay thân [promptFor] bằng một lời gọi API bất đồng bộ (ví dụ Claude API)
/// và đổi kiểu trả về thành `Future<String>`; phần UI gọi nó đã tách sẵn ở
/// widget ReflectionCard nên không phải sửa chỗ khác.
class ReflectionService {
  ReflectionService({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const _byMood = <Mood, List<String>>{
    Mood.awful: [
      'Điều gì nặng nề nhất lúc này? Thử gọi tên nó ra xem.',
      'Nếu một người bạn đang ở trong tình cảnh này, bạn sẽ nói gì với họ?',
      'Có điều gì nhỏ thôi, có thể làm ngay để bớt nặng một chút không?',
    ],
    Mood.low: [
      'Hôm nay có chuyện gì khiến bạn thấy hụt đi?',
      'Cơ thể bạn đang báo hiệu điều gì — mệt, đói, thiếu ngủ?',
      'Điều gì bạn đang kỳ vọng ở bản thân mà có thể hạ xuống được?',
    ],
    Mood.neutral: [
      'Một chi tiết nhỏ nào của hôm nay đáng được nhớ lại?',
      'Bạn đã dành nhiều thời gian nhất cho việc gì hôm nay?',
      'Nếu ngày mai giống hệt hôm nay, bạn muốn đổi điều gì?',
    ],
    Mood.good: [
      'Điều gì đã diễn ra suôn sẻ hôm nay?',
      'Ai đã góp phần vào cảm giác dễ chịu này?',
      'Thói quen nào đang thật sự có tác dụng với bạn?',
    ],
    Mood.great: [
      'Khoảnh khắc nào làm nên ngày hôm nay?',
      'Bạn muốn giữ lại điều gì từ hôm nay cho những ngày khó hơn?',
      'Bạn đã làm được gì mà chính mình cũng thấy bất ngờ?',
    ],
  };

  /// Một câu hỏi ngẫu nhiên hợp với [mood].
  String promptFor(Mood mood) {
    final prompts = _byMood[mood] ?? _byMood[Mood.neutral]!;
    return prompts[_random.nextInt(prompts.length)];
  }

  /// Câu hỏi khác câu [previous], để nút "đổi câu khác" luôn có tác dụng.
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
  'Công việc',
  'Gia đình',
  'Bạn bè',
  'Sức khỏe',
  'Học tập',
  'Nghỉ ngơi',
  'Thể thao',
  'Một mình',
];
