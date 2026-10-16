import 'dart:async';

import 'package:flutter/material.dart';

import '../core/voice_recorder.dart';
import '../l10n/l10n.dart';
import '../services/speech_service.dart';

/// Nút micro đặt trong ô nhập chữ: bấm để nói, bấm lần nữa (hoặc chờ hết 30
/// giây) để dừng; lời nói được chuyển thành chữ và thêm vào cuối ô. Dành cho
/// người khó gõ phím (biên bản họp, mục 1).
///
/// Dùng [DictationButton.maybe] cho `suffixIcon`: nơi không ghi âm được (app
/// ngoài web, trình duyệt cũ) thì không có nút nào.
class DictationButton extends StatefulWidget {
  const DictationButton({
    super.key,
    required this.controller,
    required this.recorderFactory,
    this.speech,
    this.onChanged,
  });

  /// Nút micro cho [controller], hoặc null khi máy này không ghi âm được.
  static Widget? maybe(
    TextEditingController controller, {
    VoidCallback? onChanged,
  }) {
    if (VoiceRecorder.create() == null) return null;
    return DictationButton(
      controller: controller,
      recorderFactory: VoiceRecorder.create,
      onChanged: onChanged,
    );
  }

  final TextEditingController controller;
  final VoiceRecorder? Function() recorderFactory;

  /// Mặc định là [SupabaseSpeechService]; test truyền bản giả.
  final SpeechService? speech;

  /// Gọi sau khi chữ được thêm vào ô (gán `controller.text` không gọi
  /// `onChanged` của TextField).
  final VoidCallback? onChanged;

  @override
  State<DictationButton> createState() => _DictationButtonState();
}

enum _Phase { idle, recording, working }

class _DictationButtonState extends State<DictationButton> {
  _Phase _phase = _Phase.idle;
  VoiceRecorder? _recorder;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_recorder?.cancel());
    super.dispose();
  }

  void _say(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _start() async {
    final l10n = context.l10n;
    final recorder = widget.recorderFactory();
    if (recorder == null) return _say(l10n.dictationNoMic);
    try {
      await recorder.start();
    } on MicrophoneUnavailable {
      if (mounted) _say(l10n.dictationNoMic);
      return;
    }
    if (!mounted) {
      unawaited(recorder.cancel());
      return;
    }
    _recorder = recorder;
    setState(() {
      _phase = _Phase.recording;
      _secondsLeft = SpeechService.maxDuration.inSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        unawaited(_stop());
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _stop() async {
    final recorder = _recorder;
    if (recorder == null || _phase != _Phase.recording) return;
    _timer?.cancel();
    _recorder = null;
    final language = Localizations.localeOf(context).languageCode == 'vi'
        ? 'vi'
        : 'en';
    setState(() => _phase = _Phase.working);
    final samples = await recorder.stop();
    final result = await (widget.speech ?? SupabaseSpeechService()).transcribe(
      samples,
      language: language,
    );
    if (!mounted) return;
    setState(() => _phase = _Phase.idle);
    final l10n = context.l10n;
    switch (result.outcome) {
      case SpeechOutcome.text:
        _insert(result.text);
      case SpeechOutcome.notHeard:
        _say(l10n.dictationNotHeard);
      case SpeechOutcome.busy:
        _say(l10n.dictationBusy);
      case SpeechOutcome.failed:
        _say(l10n.dictationFailed);
    }
  }

  /// Thêm vào cuối những gì đã gõ, cách bằng một dấu cách.
  void _insert(String text) {
    final current = widget.controller.text;
    final joined = current.isEmpty || RegExp(r'\s$').hasMatch(current)
        ? '$current$text'
        : '$current $text';
    widget.controller.value = TextEditingValue(
      text: joined,
      selection: TextSelection.collapsed(offset: joined.length),
    );
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return switch (_phase) {
      _Phase.idle => IconButton(
        tooltip: l10n.dictationStart,
        onPressed: _start,
        icon: const Icon(Icons.mic_none_rounded),
      ),
      _Phase.recording => Semantics(
        liveRegion: true,
        label: l10n.dictationRecording(_secondsLeft),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Text(
                '0:${_secondsLeft.toString().padLeft(2, '0')}',
                style: TextStyle(color: scheme.error),
              ),
            ),
            IconButton(
              tooltip: l10n.dictationStop,
              onPressed: _stop,
              icon: Icon(Icons.stop_circle_rounded, color: scheme.error),
            ),
          ],
        ),
      ),
      _Phase.working => Semantics(
        liveRegion: true,
        label: l10n.dictationWorking,
        child: const SizedBox.square(
          dimension: 48,
          child: Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    };
  }
}
