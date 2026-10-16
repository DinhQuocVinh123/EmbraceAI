import 'dart:typed_data';

import 'voice_recorder_stub.dart'
    if (dart.library.js_interop) 'voice_recorder_web.dart'
    as platform;

/// Ghi âm từ micro cho nút "nói thay vì gõ". Chỉ có trên bản web (trình duyệt
/// lo phần xin quyền micro); nơi khác [create] trả null và nút micro ẩn đi.
abstract class VoiceRecorder {
  /// Tần số mẫu Whisper dùng; [stop] trả về đúng tần số này, một kênh.
  static const sampleRate = 16000;

  static VoiceRecorder? create() => platform.createVoiceRecorder();

  /// Bắt đầu ghi. Ném [MicrophoneUnavailable] khi người dùng không cho phép
  /// dùng micro hoặc máy không có micro.
  Future<void> start();

  /// Dừng ghi và trả về mẫu âm thanh 16 kHz, một kênh, giá trị -1..1.
  Future<Float32List> stop();

  /// Dừng ghi, bỏ đoạn đã ghi.
  Future<void> cancel();
}

class MicrophoneUnavailable implements Exception {
  const MicrophoneUnavailable();
}
