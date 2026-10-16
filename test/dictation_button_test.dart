import 'dart:typed_data';

import 'package:embrace_ai/core/voice_recorder.dart';
import 'package:embrace_ai/core/wav.dart';
import 'package:embrace_ai/l10n/l10n.dart';
import 'package:embrace_ai/services/speech_service.dart';
import 'package:embrace_ai/widgets/dictation_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Nút nói thay vì gõ (biên bản họp, mục 1), với micro và Whisper giả.
void main() {
  late _FakeRecorder recorder;
  late _FakeSpeech speech;
  late TextEditingController controller;

  setUp(() {
    recorder = _FakeRecorder();
    speech = _FakeSpeech();
    controller = TextEditingController();
  });

  Future<void> pump(WidgetTester tester, {String locale = 'en'}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        home: Scaffold(
          body: TextField(
            controller: controller,
            decoration: InputDecoration(
              suffixIcon: DictationButton(
                controller: controller,
                recorderFactory: () => recorder,
                speech: speech,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('speaking adds the words after what was typed', (tester) async {
    controller.text = 'My shoulders';
    speech.reply = const SpeechResult(SpeechOutcome.text, 'softened a lot.');
    await pump(tester);

    await tester.tap(find.byTooltip('Speak instead of typing'));
    await tester.pump();
    expect(recorder.recording, isTrue);
    expect(find.text('0:30'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop and turn into text'));
    await tester.pumpAndSettle();
    expect(recorder.recording, isFalse);
    expect(controller.text, 'My shoulders softened a lot.');
    expect(speech.language, 'en');
  });

  testWidgets('the app language is sent to Whisper', (tester) async {
    speech.reply = const SpeechResult(SpeechOutcome.text, 'Tôi thấy nhẹ nhõm.');
    await pump(tester, locale: 'vi');

    await tester.tap(find.byTooltip('Nói thay vì gõ'));
    await tester.pump();
    await tester.tap(find.byTooltip('Dừng và chuyển thành chữ'));
    await tester.pumpAndSettle();
    expect(speech.language, 'vi');
    expect(controller.text, 'Tôi thấy nhẹ nhõm.');
  });

  testWidgets('recording stops by itself after 30 seconds', (tester) async {
    speech.reply = const SpeechResult(SpeechOutcome.text, 'Hello');
    await pump(tester);

    await tester.tap(find.byTooltip('Speak instead of typing'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('0:20'), findsOneWidget);
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(recorder.recording, isFalse);
    expect(controller.text, 'Hello');
  });

  for (final (outcome, message) in [
    (SpeechOutcome.notHeard, 'Nothing was heard'),
    (SpeechOutcome.busy, 'Voice typing is busy'),
    (SpeechOutcome.failed, 'Please type instead'),
  ]) {
    testWidgets('${outcome.name} leaves the text alone and says why', (
      tester,
    ) async {
      controller.text = 'Typed';
      speech.reply = SpeechResult(outcome);
      await pump(tester);

      await tester.tap(find.byTooltip('Speak instead of typing'));
      await tester.pump();
      await tester.tap(find.byTooltip('Stop and turn into text'));
      await tester.pumpAndSettle();
      expect(controller.text, 'Typed');
      expect(find.textContaining(message), findsOneWidget);
    });
  }

  testWidgets('a blocked microphone is explained, nothing is recorded', (
    tester,
  ) async {
    recorder.allowed = false;
    await pump(tester);

    await tester.tap(find.byTooltip('Speak instead of typing'));
    await tester.pumpAndSettle();
    expect(find.textContaining('microphone is not available'), findsOneWidget);
    expect(find.byTooltip('Speak instead of typing'), findsOneWidget);
    expect(speech.calls, 0);
  });

  testWidgets('no microphone button where recording is not possible', (
    tester,
  ) async {
    // Test chạy ngoài trình duyệt, giống app Android/iOS: không có nút.
    expect(DictationButton.maybe(controller), isNull);
  });

  test('silence is not sent to Whisper', () async {
    // Máy chủ giả không tồn tại: nếu đoạn im lặng bị gửi đi thì kết quả là busy.
    final service = SupabaseSpeechService(
      client: SupabaseClient(
        'https://example.invalid',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    );
    final result = await service.transcribe(Float32List(16000));
    expect(result.outcome, SpeechOutcome.notHeard);
  });

  test('peak level tells speech from silence', () {
    expect(peakLevel(Float32List(16000)), 0);
    expect(peakLevel(Float32List.fromList([0.1, -0.5, 0.2])), 0.5);
  });

  test('WAV header matches what whisper.cpp reads', () {
    final wav = encodeWav(Float32List.fromList([0, 1, -1]), 16000);
    final data = ByteData.sublistView(wav);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(data.getUint16(22, Endian.little), 1); // một kênh
    expect(data.getUint32(24, Endian.little), 16000);
    expect(data.getUint16(34, Endian.little), 16);
    expect(data.getUint32(40, Endian.little), 6);
    expect(wav.length, 44 + 6);
    expect(data.getInt16(46, Endian.little), 32767);
    expect(data.getInt16(48, Endian.little), -32767);
  });
}

class _FakeRecorder implements VoiceRecorder {
  bool allowed = true;
  bool recording = false;

  @override
  Future<void> start() async {
    if (!allowed) throw const MicrophoneUnavailable();
    recording = true;
  }

  @override
  Future<Float32List> stop() async {
    recording = false;
    return Float32List.fromList([0.3, -0.4, 0.2]);
  }

  @override
  Future<void> cancel() async => recording = false;
}

class _FakeSpeech implements SpeechService {
  SpeechResult reply = const SpeechResult(SpeechOutcome.failed);
  String? language;
  int calls = 0;

  @override
  Future<SpeechResult> transcribe(
    Float32List samples, {
    String language = 'en',
  }) async {
    calls++;
    this.language = language;
    return reply;
  }
}
