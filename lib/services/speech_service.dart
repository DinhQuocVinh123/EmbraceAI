import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/voice_recorder.dart';
import '../core/wav.dart';

/// Kết quả chuyển giọng nói thành chữ.
enum SpeechOutcome { text, notHeard, busy, failed }

class SpeechResult {
  const SpeechResult(this.outcome, [this.text = '']);

  final SpeechOutcome outcome;
  final String text;
}

/// Nói thay vì gõ: đoạn ghi âm được gửi tới Edge Function `transcribe`, rồi
/// tới Whisper chạy trên máy GPU của nhóm (không qua dịch vụ AI bên ngoài).
/// Đoạn ghi không được lưu lại ở đâu.
abstract class SpeechService {
  /// Đoạn ghi dài nhất; nút micro tự dừng khi tới.
  static const maxDuration = Duration(seconds: 30);

  /// [samples] là âm thanh 16 kHz một kênh; [language] là `en` hoặc `vi`.
  Future<SpeechResult> transcribe(Float32List samples, {String language});
}

class SupabaseSpeechService implements SpeechService {
  SupabaseSpeechService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Đỉnh âm dưới mức này coi như không nói gì.
  static const _silence = 0.02;

  @override
  Future<SpeechResult> transcribe(
    Float32List samples, {
    String language = 'en',
  }) async {
    if (samples.isEmpty || peakLevel(samples) < _silence) {
      return const SpeechResult(SpeechOutcome.notHeard);
    }
    final wav = encodeWav(samples, VoiceRecorder.sampleRate);
    try {
      final response = await _client.functions.invoke(
        'transcribe',
        body: {'audio': base64Encode(wav), 'language': language},
      );
      final data = response.data;
      final text = data is Map ? (data['text'] as String? ?? '').trim() : '';
      return text.isEmpty
          ? const SpeechResult(SpeechOutcome.notHeard)
          : SpeechResult(SpeechOutcome.text, text);
    } on FunctionException catch (error) {
      return SpeechResult(
        error.status == 429 || error.status == 503
            ? SpeechOutcome.busy
            : SpeechOutcome.failed,
      );
    } catch (_) {
      return const SpeechResult(SpeechOutcome.busy);
    }
  }
}
