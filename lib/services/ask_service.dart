import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ask_result.dart';

/// Trợ lý Ask EmbraceAI phía app.
///
/// Màn hình chỉ biết interface này, nên test dùng bản giả và phía máy chủ
/// (model tự host, Edge Function) đổi được mà không đụng tới giao diện.
abstract class AskService {
  static const maxQuestionLength = 500;

  /// Tài khoản này có được dùng thử trợ lý không (`participants.ai_enabled`).
  Future<bool> isEnabled();

  Future<AskResult> ask(String question);
}

class SupabaseAskService implements AskService {
  SupabaseAskService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<bool> isEnabled() async {
    try {
      // RLS chỉ trả về đúng dòng của người đang đăng nhập.
      final row = await _client
          .from('participants')
          .select('ai_enabled')
          .maybeSingle();
      return row?['ai_enabled'] == true;
    } catch (_) {
      // Database chưa có cột này, hoặc mất mạng: coi như chưa bật.
      return false;
    }
  }

  @override
  Future<AskResult> ask(String question) async {
    try {
      final response = await _client.functions.invoke(
        'ask-embrace',
        body: {'question': question},
      );
      final data = response.data;
      return data is Map<String, dynamic>
          ? AskResult.fromJson(data)
          : AskResult.error;
    } on FunctionException catch (error) {
      return error.status == 429 || error.status == 503
          ? AskResult.busy
          : AskResult.error;
    } catch (_) {
      // Không tới được máy chủ: thường là mạng chập chờn, thử lại là được.
      return AskResult.busy;
    }
  }
}
