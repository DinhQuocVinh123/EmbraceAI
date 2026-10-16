import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'voice_recorder.dart';

/// Trình duyệt cũ hoặc trang không chạy trên https thì không có micro.
VoiceRecorder? createVoiceRecorder() =>
    web.window.navigator.has('mediaDevices') && web.window.has('MediaRecorder')
    ? _WebVoiceRecorder()
    : null;

/// Ghi bằng MediaRecorder (Chrome cho webm/opus, Safari cho mp4/aac), rồi để
/// trình duyệt tự giải mã và đổi sang 16 kHz một kênh bằng OfflineAudioContext.
class _WebVoiceRecorder implements VoiceRecorder {
  web.MediaStream? _stream;
  web.MediaRecorder? _recorder;
  final _chunks = <web.Blob>[];
  Completer<void>? _stopped;

  @override
  Future<void> start() async {
    try {
      _stream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
          .toDart;
    } catch (_) {
      throw const MicrophoneUnavailable();
    }
    _chunks.clear();
    final stopped = _stopped = Completer<void>();
    final recorder = _recorder = web.MediaRecorder(_stream!);
    recorder.ondataavailable = ((web.BlobEvent event) {
      if (event.data.size > 0) _chunks.add(event.data);
    }).toJS;
    recorder.onstop = ((web.Event _) {
      if (!stopped.isCompleted) stopped.complete();
    }).toJS;
    recorder.start();
  }

  @override
  Future<Float32List> stop() async {
    final recorder = _recorder;
    if (recorder == null) return Float32List(0);
    if (recorder.state != 'inactive') recorder.stop();
    await _stopped?.future;
    _release();
    if (_chunks.isEmpty) return Float32List(0);

    final blob = web.Blob(_chunks.toJS);
    final encoded = await blob.arrayBuffer().toDart;
    final context = web.AudioContext();
    try {
      final decoded = await context.decodeAudioData(encoded).toDart;
      final frames = (decoded.duration * VoiceRecorder.sampleRate).ceil();
      if (frames <= 0) return Float32List(0);
      final offline = web.OfflineAudioContext(
        1.toJS,
        frames,
        VoiceRecorder.sampleRate,
      );
      final source = offline.createBufferSource()..buffer = decoded;
      source.connect(offline.destination);
      source.start();
      final rendered = await offline.startRendering().toDart;
      return rendered.getChannelData(0).toDart;
    } finally {
      unawaited(context.close().toDart);
    }
  }

  @override
  Future<void> cancel() async {
    final recorder = _recorder;
    if (recorder != null && recorder.state != 'inactive') recorder.stop();
    _release();
    _chunks.clear();
  }

  /// Tắt micro ngay, để đèn báo micro của trình duyệt không sáng mãi.
  void _release() {
    final tracks = _stream?.getTracks().toDart ?? const [];
    for (final track in tracks) {
      track.stop();
    }
    _stream = null;
    _recorder = null;
  }
}
