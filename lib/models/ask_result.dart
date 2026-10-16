/// Kết quả một lần hỏi Ask EmbraceAI, theo đúng hợp đồng với Edge Function
/// `ask-embrace`: `{type, domain, answer, also_asked, sources: [{title, heading}]}`.
enum AskResultType {
  answer('answer'),
  medicalRedirect('medical_redirect'),
  outOfScope('out_of_scope'),
  notFound('not_found'),
  emergency('emergency'),
  busy('busy'),
  error('error');

  const AskResultType(this.wire);

  /// Tên loại kết quả như máy chủ gửi về.
  final String wire;

  /// Loại lạ từ máy chủ được coi là lỗi, không bao giờ hiện như câu trả lời.
  static AskResultType fromWire(Object? value) => values.firstWhere(
    (type) => type.wire == value,
    orElse: () => AskResultType.error,
  );
}

/// Đoạn tài liệu đã duyệt mà câu trả lời dựa vào.
class AskSource {
  const AskSource({required this.title, required this.heading});

  /// Tên tài liệu, ví dụ User Guide.
  final String title;

  /// Tiêu đề mục trong tài liệu.
  final String heading;

  factory AskSource.fromJson(Map<String, dynamic> json) => AskSource(
    title: (json['title'] as String? ?? '').trim(),
    heading: (json['heading'] as String? ?? '').trim(),
  );
}

class AskResult {
  const AskResult({
    required this.type,
    this.answer = '',
    this.sources = const [],
    this.alsoAsked = false,
    this.healthTopic = false,
  });

  static const busy = AskResult(type: AskResultType.busy);
  static const error = AskResult(type: AskResultType.error);

  final AskResultType type;

  /// Chữ do model viết; trống với các loại không có chữ của AI.
  final String answer;
  final List<AskSource> sources;

  /// Câu hỏi y tế có kèm một ý khác: app nhắc hỏi riêng phần đó, vì không bao
  /// giờ hiện chữ do model viết cho câu y tế.
  final bool alsoAsked;

  /// Câu hỏi thuộc một lĩnh vực sức khoẻ (biên bản họp, mục 3): app hiện thêm
  /// dòng nhắc cố định "thông tin chung, không phải chẩn đoán".
  final bool healthTopic;

  /// Chỉ ba loại này mang chữ do model viết, nên chỉ chúng mang nhãn AI.
  bool get writtenByAi =>
      answer.isNotEmpty &&
      (type == AskResultType.answer ||
          type == AskResultType.medicalRedirect ||
          type == AskResultType.outOfScope);

  factory AskResult.fromJson(Map<String, dynamic> json) {
    final type = AskResultType.fromWire(json['type']);
    final sources = (json['sources'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AskSource.fromJson)
        .where((source) => source.heading.isNotEmpty)
        .toList(growable: false);
    // Thẻ khẩn cấp không bao giờ hiện chữ của AI, kể cả khi máy chủ có gửi.
    final answer = type == AskResultType.emergency
        ? ''
        : (json['answer'] as String? ?? '').trim();
    return AskResult(
      type: type,
      answer: answer,
      sources: sources,
      alsoAsked:
          type == AskResultType.medicalRedirect && json['also_asked'] == true,
      healthTopic: const {
        'health',
        'wellbeing',
        'lifestyle',
      }.contains(json['domain']),
    );
  }
}
