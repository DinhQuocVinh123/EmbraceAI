import 'dart:io';
import 'dart:typed_data';

import 'package:embrace_ai/data/session_script.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:embrace_ai/models/session_answers.dart';
import 'package:embrace_ai/models/session_scene.dart';
import 'package:embrace_ai/screens/journal_screen.dart';
import 'package:embrace_ai/screens/session_screen.dart';
import 'package:embrace_ai/screens/welcome_screen.dart';
import 'package:embrace_ai/state/journal_store.dart';
import 'package:embrace_ai/state/settings_store.dart';
import 'package:embrace_ai/widgets/session_chrome.dart';
import 'package:embrace_ai/widgets/session_prompts.dart';
import 'package:embrace_ai/widgets/session_help.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_repository.dart';
import 'support/screenshot_harness.dart';

/// Chụp lại các màn hình chính để gửi cho người xem từ xa.
///
/// Đây không phải test hồi quy: chạy với `--update-goldens` để sinh ảnh.
/// Khung hình nền lấy thẳng từ `assets/video/meditation_8min.mp4`, còn toàn bộ
/// lớp giao diện là widget thật của app (`SessionStage`, các `*Prompt`), nên
/// ảnh phản ánh đúng thứ chạy trên máy.
void main() {
  late Map<int, _Frame> frames;
  late Map<int, _Frame> beachFrames;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('en');
    await ScreenshotHarness.loadFonts();
    frames = {
      for (final t in [20, 64, 94, 424, 479])
        t: _Frame(File('test/fixtures/frame_$t.png').readAsBytesSync()),
    };
    beachFrames = {
      for (final t in [20, 94, 290, 432])
        t: _Frame(File('test/fixtures/beach_$t.png').readAsBytesSync()),
    };
  });

  Future<void> shoot(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  /// Dựng một khoảnh khắc của buổi thiền: nền là khung hình thật ở giây [at].
  Future<void> pumpStage(
    WidgetTester tester, {
    required int at,
    required int beatNumber,
    required String beatTitle,
    String? caption,
    Widget? prompt,
    SettingsStore? settings,
    SessionScene scene = SessionScene.countryside,
  }) async {
    ScreenshotHarness.sizePhone(tester);
    if (prompt != null) {
      await tester.pumpWidget(
        ScreenshotHarness.wrap(
          Scaffold(
            appBar: AppBar(
              title: Text(at < 95 ? 'Before you begin' : 'After your practice'),
            ),
            body: SafeArea(child: SingleChildScrollView(child: prompt)),
          ),
          settings: settings,
        ),
      );
      await tester.pumpAndSettle();
      return;
    }
    final frame = (scene == SessionScene.beach ? beachFrames : frames)[at]!;
    await ScreenshotHarness.preload(tester, frame.image);
    await tester.pumpWidget(
      ScreenshotHarness.wrap(
        Scaffold(
          backgroundColor: Colors.black,
          body: SessionStage(
            videoSurface: Image(image: frame.image, fit: BoxFit.cover),
            // Lấy từ chính khung hình, không viết cứng: hai bối cảnh có tỉ lệ
            // khác nhau sau khi bản quê được cắt bỏ chữ nung cứng.
            aspectRatio: frame.aspectRatio,
            beatNumber:
                SessionScript.practiceBeats().indexOf(
                  SessionScript.beatAt(Duration(seconds: at)),
                ) +
                1,
            beatTitle: beatTitle,
            totalBeats: SessionScript.practiceBeats().length,
            position: Duration(
              seconds:
                  at -
                  (at >= 425
                      ? 95
                      : at >= 95
                      ? 50
                      : 0),
            ),
            total: SessionScript.practiceDuration(),
            isPlaying: prompt == null,
            highClarity: settings?.highClarity ?? false,
            caption: caption,
            onHelp: () {},
            onStop: () {},
            onTogglePlay: () {},
          ),
        ),
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('01 mở app', (tester) async {
    ScreenshotHarness.sizePhone(tester);
    await tester.pumpWidget(
      ScreenshotHarness.wrap(
        const Scaffold(body: WelcomeScreen()),
        journal: JournalStore(FakeRepository())..load(),
      ),
    );
    await tester.pumpAndSettle();
    await shoot(tester, '01_welcome');
  });

  testWidgets('02 bật chế độ dễ nhìn, chữ 150%', (tester) async {
    final settings = SettingsStore();
    await settings.enableAssistedView();
    ScreenshotHarness.sizePhone(tester);
    await tester.pumpWidget(
      ScreenshotHarness.wrap(
        const Scaffold(body: WelcomeScreen()),
        settings: settings,
        journal: JournalStore(FakeRepository())..load(),
      ),
    );
    await tester.pumpAndSettle();
    await shoot(tester, '02_welcome_de_nhin');
  });

  testWidgets('03 đang phát, phụ đề do app vẽ', (tester) async {
    await pumpStage(
      tester,
      at: 20,
      beatNumber: 1,
      beatTitle: 'Arrival and orientation',
      caption:
          "I'll guide you through a short relaxation exercise using "
          'gentle breathing and present-moment awareness.',
    );
    await shoot(tester, '03_dang_phat');
  });

  testWidgets('04 cùng cảnh đó ở chế độ dễ nhìn', (tester) async {
    final settings = SettingsStore();
    await settings.enableAssistedView();
    await pumpStage(
      tester,
      at: 20,
      beatNumber: 1,
      beatTitle: 'Arrival and orientation',
      caption:
          "I'll guide you through a short relaxation exercise using "
          'gentle breathing and present-moment awareness.',
      settings: settings,
    );
    await shoot(tester, '04_dang_phat_de_nhin');
  });

  testWidgets('05 kiểm tra an toàn', (tester) async {
    await pumpStage(
      tester,
      at: 64,
      beatNumber: 2,
      beatTitle: 'Safety check',
      prompt: SafetyPrompt(onAnswer: (_) {}, onSkip: () {}),
    );
    await shoot(tester, '05_an_toan');
  });

  testWidgets('06 hỏi tâm trạng', (tester) async {
    await pumpStage(
      tester,
      at: 94,
      beatNumber: 3,
      beatTitle: 'Check-in',
      prompt: CheckInPrompt(onDone: (a, b, c, d) {}, onSkip: () {}),
    );
    await shoot(tester, '06_tam_trang');
  });

  testWidgets('07 thang căng thẳng 0-10', (tester) async {
    await pumpStage(
      tester,
      at: 94,
      beatNumber: 3,
      beatTitle: 'Check-in',
      prompt: CheckInPrompt(onDone: (a, b, c, d) {}, onSkip: () {}),
    );
    await tester.tap(find.text(CheckInFeeling.stressed.label));
    await tester.pumpAndSettle();
    await shoot(tester, '07_thang_cang_thang');
  });

  testWidgets('08 chọn bài sau khi báo căng cao', (tester) async {
    await pumpStage(
      tester,
      at: 94,
      beatNumber: 3,
      beatTitle: 'Check-in',
      prompt: CheckInPrompt(onDone: (a, b, c, d) {}, onSkip: () {}),
    );
    await tester.tap(find.text(CheckInFeeling.stressed.label));
    await tester.pumpAndSettle();
    // Kéo thang lên mức cao để thấy app đổi lời dẫn.
    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await shoot(tester, '08_chon_bai');
  });

  testWidgets('09 câu hỏi mang tới buổi khám', (tester) async {
    await pumpStage(
      tester,
      at: 424,
      beatNumber: 9,
      beatTitle: 'Healthcare preparation',
      prompt: QuestionPrompt(onAnswer: (_) {}, onSkip: () {}),
    );
    await shoot(tester, '09_cau_hoi');
  });

  testWidgets('10 đo lại căng thẳng cuối buổi', (tester) async {
    await pumpStage(
      tester,
      at: 479,
      beatNumber: 11,
      beatTitle: 'After-session feedback',
      prompt: FeedbackPrompt(stressBefore: 8, onDone: (a, b, c) {}),
    );
    await shoot(tester, '10_phan_hoi');
  });

  testWidgets('11 tổng kết', (tester) async {
    ScreenshotHarness.sizePhone(tester);
    final a = SessionAnswers()
      ..feeling = CheckInFeeling.stressed
      ..stressBefore = 8
      ..stressAfter = 4
      ..practice = PracticeChoice.grounding
      ..question = 'How will this test result affect my daily life?'
      ..reflection = 'My shoulders softened, my breathing slowed at the end.';
    await tester.pumpWidget(
      ScreenshotHarness.wrap(
        Scaffold(
          body: SummaryView(answers: a, onSave: () {}, onSkip: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await shoot(tester, '11_tong_ket');
  });

  testWidgets('12 buổi tập nằm trong nhật ký', (tester) async {
    ScreenshotHarness.sizePhone(tester);
    final store = JournalStore(
      FakeRepository([
        fakeEntry(
          id: 1,
          daysAgo: 0,
          mood: Mood.low,
          tags: ['Session'],
          note:
              'My shoulders softened, my breathing slowed at the end.\n'
              'Question for the team: how will this affect daily life?\n'
              'Stress: 8 → 4',
        ),
        fakeEntry(
          id: 2,
          daysAgo: 1,
          mood: Mood.neutral,
          note: 'An ordinary day.',
        ),
      ]),
    );
    await store.load();
    await tester.pumpWidget(
      ScreenshotHarness.wrap(
        Scaffold(
          body: JournalScreen(
            now: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              12,
            ),
          ),
        ),
        journal: store,
      ),
    );
    await tester.pumpAndSettle();
    await shoot(tester, '12_nhat_ky');
  });

  testWidgets('13 bối cảnh biển, cùng câu phụ đề', (tester) async {
    await pumpStage(
      tester,
      at: 20,
      beatNumber: 1,
      beatTitle: 'Arrival and orientation',
      scene: SessionScene.beach,
      caption:
          "I'll guide you through a short relaxation exercise using "
          'gentle breathing and present-moment awareness.',
    );
    await shoot(tester, '13_bien_dang_phat');
  });

  testWidgets('14 bối cảnh biển, hỏi tâm trạng', (tester) async {
    await pumpStage(
      tester,
      at: 94,
      beatNumber: 3,
      beatTitle: 'Check-in',
      scene: SessionScene.beach,
      prompt: CheckInPrompt(onDone: (a, b, c, d) {}, onSkip: () {}),
    );
    await shoot(tester, '14_bien_tam_trang');
  });

  testWidgets('15 bối cảnh biển, đoạn cảm nhận cơ thể', (tester) async {
    await pumpStage(
      tester,
      at: 290,
      beatNumber: 7,
      beatTitle: 'Body awareness',
      scene: SessionScene.beach,
      caption: 'Perhaps you notice warmth… coolness… or areas of tension.',
    );
    await shoot(tester, '15_bien_co_bien');
  });

  testWidgets('16 bối cảnh biển lúc hoàng hôn', (tester) async {
    await pumpStage(
      tester,
      at: 432,
      beatNumber: 10,
      beatTitle: 'Closing',
      scene: SessionScene.beach,
      caption:
          'Even a few moments of slowing down can become part of caring '
          'for yourself.',
    );
    await shoot(tester, '16_bien_hoang_hon');
  });

  testWidgets('17 help at 200 percent', (tester) async {
    ScreenshotHarness.sizePhone(tester);
    final settings = SettingsStore();
    await settings.setTextScale(2);
    await tester.pumpWidget(
      ScreenshotHarness.wrap(
        Scaffold(body: SessionHelp(settings: settings)),
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();
    await shoot(tester, '17_help_large_text');
  });

  testWidgets('18 practice at 200 percent', (tester) async {
    final settings = SettingsStore();
    await settings.setTextScale(2);
    await pumpStage(
      tester,
      at: 20,
      beatNumber: 1,
      beatTitle: 'Arrival and orientation',
      settings: settings,
      caption:
          "I'll guide you through a short relaxation exercise using "
          'gentle breathing and present-moment awareness.',
    );
    await shoot(tester, '18_practice_large_text');
  });
}

/// Một khung hình lấy ra từ video thật, kèm đúng tỉ lệ khung của nó.
///
/// Tỉ lệ đọc thẳng từ phần đầu file PNG thay vì viết cứng trong test — viết
/// cứng thì ảnh chụp vẫn xanh trong khi app thật hiển thị sai hình dạng.
class _Frame {
  _Frame(Uint8List bytes)
    : image = MemoryImage(bytes),
      width = _beInt(bytes, 16),
      height = _beInt(bytes, 20);

  final MemoryImage image;
  final int width;
  final int height;

  double get aspectRatio => width / height;

  static int _beInt(Uint8List b, int at) =>
      (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];
}
