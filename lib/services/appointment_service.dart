import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment_question.dart';

enum PrepOutcome { question, emergency, busy, error }

/// Kết quả nhờ AI viết lại câu hỏi. [text] chỉ có khi [outcome] là question.
class PrepResult {
  const PrepResult(this.outcome, [this.text = '']);

  final PrepOutcome outcome;
  final String text;
}

/// Thẻ "chuẩn bị câu hỏi cho buổi khám" (biên bản họp, mục 2): nhờ AI viết lại
/// và lưu tối đa [maxQuestions] câu. Câu hỏi chỉ chính người tham gia đọc được
/// (RLS của bảng appointment_questions).
///
/// Màn hình chỉ biết interface này, nên test dùng bản giả.
abstract class AppointmentService {
  static const maxQuestions = 3;
  static const maxConcernLength = 1000;
  static const maxQuestionLength = 600;

  /// Các câu đã lưu, câu muốn hỏi trước đứng đầu.
  Future<List<AppointmentQuestion>> load();

  /// Nhờ model tự host viết lại lời người tham gia. [previous] là cách viết họ
  /// vừa bấm "thử cách viết khác".
  Future<PrepResult> rephrase({
    required String concern,
    required List<AppointmentTopic> topics,
    required String language,
    String? previous,
  });

  /// Lưu thêm một câu vào cuối danh sách.
  Future<AppointmentQuestion> add({
    required String question,
    String concern = '',
    List<AppointmentTopic> topics = const [],
  });

  Future<void> update(String id, String question);

  Future<void> remove(String id);

  /// Ghi lại thứ tự theo đúng thứ tự của [ordered].
  Future<void> reorder(List<AppointmentQuestion> ordered);
}

class SupabaseAppointmentService implements AppointmentService {
  SupabaseAppointmentService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  String? _participantCode;

  static const _table = 'appointment_questions';

  @override
  Future<List<AppointmentQuestion>> load() async {
    final rows = await _client
        .from(_table)
        .select('id, question, concern, topics, position')
        .order('position')
        .order('created_at');
    return rows.map(AppointmentQuestion.fromSupabase).toList(growable: false);
  }

  @override
  Future<PrepResult> rephrase({
    required String concern,
    required List<AppointmentTopic> topics,
    required String language,
    String? previous,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'prepare-question',
        body: {
          'concern': concern,
          'topics': [for (final topic in topics) topic.code],
          'language': language,
          'previous': ?previous,
        },
      );
      final data = response.data;
      if (data is! Map) return const PrepResult(PrepOutcome.error);
      return switch (data['type']) {
        'question' => PrepResult(
          PrepOutcome.question,
          data['question'] as String? ?? '',
        ),
        'emergency' => const PrepResult(PrepOutcome.emergency),
        'busy' => const PrepResult(PrepOutcome.busy),
        _ => const PrepResult(PrepOutcome.error),
      };
    } on FunctionException catch (error) {
      return PrepResult(
        error.status == 429 || error.status == 503
            ? PrepOutcome.busy
            : PrepOutcome.error,
      );
    } catch (_) {
      // Mất mạng: thử lại thường là được.
      return const PrepResult(PrepOutcome.busy);
    }
  }

  @override
  Future<AppointmentQuestion> add({
    required String question,
    String concern = '',
    List<AppointmentTopic> topics = const [],
  }) async {
    // RLS chỉ trả về đúng dòng của người đang đăng nhập.
    final code = _participantCode ??=
        (await _client
                .from('participants')
                .select('participant_code')
                .single())['participant_code']
            as String;
    final existing = await load();
    final row = await _client
        .from(_table)
        .insert({
          'participant_code': code,
          'question': question.trim(),
          'concern': concern.trim(),
          'topics': [for (final topic in topics) topic.code],
          'position': existing.length,
        })
        .select('id, question, concern, topics, position')
        .single();
    return AppointmentQuestion.fromSupabase(row);
  }

  @override
  Future<void> update(String id, String question) async {
    await _client
        .from(_table)
        .update({
          'question': question.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<void> remove(String id) async {
    await _client.from(_table).delete().eq('id', id);
    await reorder(await load());
  }

  @override
  Future<void> reorder(List<AppointmentQuestion> ordered) async {
    for (final (index, question) in ordered.indexed) {
      if (question.position == index) continue;
      await _client
          .from(_table)
          .update({'position': index})
          .eq('id', question.id);
    }
  }
}
