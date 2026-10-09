import 'package:embrace_ai/core/theme.dart';
import 'package:embrace_ai/models/ask_result.dart';
import 'package:embrace_ai/screens/ask_screen.dart';
import 'package:embrace_ai/screens/welcome_screen.dart';
import 'package:embrace_ai/services/ask_service.dart';
import 'package:embrace_ai/state/journal_store.dart';
import 'package:embrace_ai/state/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_repository.dart';

/// Máy chủ giả: trả đúng kết quả đã soạn cho từng câu hỏi.
class FakeAskService implements AskService {
  FakeAskService(this.results, {this.enabled = true});

  final Map<String, AskResult> results;
  final bool enabled;
  final asked = <String>[];

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<AskResult> ask(String question) async {
    asked.add(question);
    return results[question] ?? AskResult.error;
  }
}

const _answer = AskResult(
  type: AskResultType.answer,
  answer: 'A session takes about 5 to 10 minutes including the questions.',
  sources: [
    AskSource(
      title: 'User Guide',
      heading: 'Participant app: a guided session',
    ),
  ],
);

Future<FakeRepository> _pumpAsk(
  WidgetTester tester,
  FakeAskService service, {
  double textScale = 1,
}) async {
  final repository = FakeRepository();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => JournalStore(repository),
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: AskScreen(service: service),
      ),
    ),
  );
  return repository;
}

Future<void> _ask(WidgetTester tester, String question) async {
  await tester.enterText(find.byType(TextField), question);
  await tester.tap(find.byTooltip('Send'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('unknown result types from the server become errors', () {
    final result = AskResult.fromJson({'type': 'something_new', 'answer': 'x'});
    expect(result.type, AskResultType.error);
    expect(result.writtenByAi, isFalse);
  });

  test('an emergency never carries AI-written text', () {
    final result = AskResult.fromJson({
      'type': 'emergency',
      'answer': 'Some model text',
    });
    expect(result.answer, isEmpty);
  });

  test('only a medical question can say something else was asked', () {
    final medical = AskResult.fromJson({
      'type': 'medical_redirect',
      'also_asked': true,
    });
    final answer = AskResult.fromJson({'type': 'answer', 'also_asked': true});
    expect(medical.alsoAsked, isTrue);
    expect(answer.alsoAsked, isFalse);
  });

  testWidgets('an answer shows its sources and the AI label', (tester) async {
    final service = FakeAskService({'How long does a session take?': _answer});
    await _pumpAsk(tester, service);

    await tester.tap(find.text('How long does a session take?'));
    await tester.pumpAndSettle();

    expect(service.asked, ['How long does a session take?']);
    expect(find.textContaining('5 to 10 minutes'), findsOneWidget);
    expect(find.text('Sources'), findsOneWidget);
    expect(
      find.text('Participant app: a guided session · User Guide'),
      findsOneWidget,
    );
    expect(
      find.text('AI-generated from study materials. Not medical advice.'),
      findsOneWidget,
    );
    // Gợi ý câu hỏi chỉ hiện trước câu đầu tiên.
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('a medical question can be saved for the appointment', (
    tester,
  ) async {
    const question = 'Should I lower my medication dose?';
    final service = FakeAskService({
      question: const AskResult(
        type: AskResultType.medicalRedirect,
        answer: 'That is a question for your doctor.',
      ),
    });
    final repository = await _pumpAsk(tester, service);

    await _ask(tester, question);
    expect(find.text('A question for your care team'), findsOneWidget);

    await tester.tap(find.text('Save for my appointment'));
    await tester.pumpAndSettle();

    expect(find.text('Saved to your journal'), findsOneWidget);
    final saved = (await repository.fetchAll()).single;
    expect(saved.tags, ['Appointment']);
    expect(saved.note, 'Question for my appointment: $question');
    expect(find.textContaining('You also asked'), findsNothing);
  });

  testWidgets('a medical question with another part asks for it separately', (
    tester,
  ) async {
    const question =
        'How long is a session, and should I stop my beta blockers?';
    final service = FakeAskService({
      question: AskResult.fromJson({
        'type': 'medical_redirect',
        'answer': '',
        'also_asked': true,
      }),
    });
    await _pumpAsk(tester, service);

    await _ask(tester, question);

    expect(find.text('A question for your care team'), findsOneWidget);
    expect(
      find.text(
        'You also asked about something else. Please ask that part on its own.',
      ),
      findsOneWidget,
    );
    expect(find.text('Save for my appointment'), findsOneWidget);
    // Câu y tế không bao giờ mang chữ của model, nên không có nhãn AI.
    expect(
      find.text('AI-generated from study materials. Not medical advice.'),
      findsNothing,
    );
  });

  testWidgets('an emergency shows fixed help and no AI text', (tester) async {
    const question = 'I have chest pain right now';
    final service = FakeAskService({
      question: AskResult.fromJson({
        'type': 'emergency',
        'answer': 'Model text',
      }),
    });
    await _pumpAsk(tester, service);

    await _ask(tester, question);

    expect(find.text('If this is an emergency, get help now'), findsOneWidget);
    expect(find.text('Model text'), findsNothing);
    expect(
      find.text('AI-generated from study materials. Not medical advice.'),
      findsNothing,
    );
  });

  testWidgets('a busy server asks to try again', (tester) async {
    final service = FakeAskService({'hello': AskResult.busy});
    await _pumpAsk(tester, service);

    await _ask(tester, 'hello');

    expect(find.textContaining('busy right now'), findsOneWidget);
  });

  testWidgets('stays usable at 200 percent text', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final service = FakeAskService({'How long does a session take?': _answer});
    await _pumpAsk(tester, service, textScale: 2);

    await _ask(tester, 'How long does a session take?');

    expect(tester.takeException(), isNull);
    // Thẻ trả lời cao hơn màn hình ở cỡ chữ này; ô nhập vẫn phải dùng được.
    expect(find.text('Sources', skipOffstage: false), findsOneWidget);
    expect(find.byTooltip('Send'), findsOneWidget);
  });

  group('the Ask EmbraceAI entry on the session tab', () {
    Future<void> pumpWelcome(WidgetTester tester, AskService service) async {
      final settings = SettingsStore();
      await settings.load();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider(
              create: (_) => JournalStore(FakeRepository()),
            ),
            Provider<AskService>.value(value: service),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: WelcomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('is hidden unless the account is enabled', (tester) async {
      await pumpWelcome(tester, FakeAskService({}, enabled: false));
      expect(find.text('Ask EmbraceAI (preview)'), findsNothing);
    });

    testWidgets('opens the assistant when enabled', (tester) async {
      await pumpWelcome(tester, FakeAskService({}));
      final entry = find.text('Ask EmbraceAI (preview)');
      // Thẻ nằm cuối danh sách dài: cuộn tới để nó được dựng, rồi đưa trọn
      // vào khung nhìn trước khi bấm.
      await tester.scrollUntilVisible(entry, 300);
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.text('Ask about the exercises or the app'), findsOneWidget);
    });
  });
}
