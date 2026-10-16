/// Điều người tham gia muốn hỏi, đúng bốn lựa chọn trong biên bản họp (mục 2).
/// [code] là giá trị lưu xuống database và gửi cho Edge Function.
enum AppointmentTopic {
  why('why'),
  monitor('monitor'),
  nextTime('next_time'),
  other('other');

  const AppointmentTopic(this.code);

  final String code;

  static AppointmentTopic? fromCode(String code) {
    for (final topic in values) {
      if (topic.code == code) return topic;
    }
    return null;
  }
}

/// Một câu hỏi người tham gia muốn mang tới buổi khám. Mỗi người tối đa 3 câu,
/// xếp theo [position] (0 là câu muốn hỏi trước nhất).
class AppointmentQuestion {
  const AppointmentQuestion({
    required this.id,
    required this.question,
    this.concern = '',
    this.topics = const [],
    this.position = 0,
  });

  final String id;
  final String question;

  /// Lời người tham gia tự kể lúc chuẩn bị câu hỏi; có thể rỗng.
  final String concern;
  final List<AppointmentTopic> topics;
  final int position;

  factory AppointmentQuestion.fromSupabase(Map<String, dynamic> data) {
    return AppointmentQuestion(
      id: data['id'] as String,
      question: data['question'] as String,
      concern: data['concern'] as String? ?? '',
      topics: [
        for (final code in (data['topics'] as List?) ?? const [])
          ?AppointmentTopic.fromCode('$code'),
      ],
      position: (data['position'] as num?)?.toInt() ?? 0,
    );
  }

  AppointmentQuestion copyWith({String? question, int? position}) {
    return AppointmentQuestion(
      id: id,
      question: question ?? this.question,
      concern: concern,
      topics: topics,
      position: position ?? this.position,
    );
  }
}
