import 'dart:async';

import 'package:embrace_ai/core/theme.dart';
import 'package:embrace_ai/l10n/l10n.dart';
import 'package:embrace_ai/models/appointment_question.dart';
import 'package:embrace_ai/screens/appointment_questions_screen.dart';
import 'package:embrace_ai/services/appointment_service.dart';
import 'package:embrace_ai/widgets/appointment_prep_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Thẻ chuẩn bị câu hỏi cho buổi khám (biên bản họp, mục 2), với máy chủ giả.
void main() {
  late _FakeAppointments service;

  setUp(() => service = _FakeAppointments());

  Future<void> pump(
    WidgetTester tester, {
    double textScale = 1,
    String locale = 'en',
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: AppointmentQuestionsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Mở thẻ, kể điều lo, chọn chủ đề, chờ AI.
  Future<void> describe(
    WidgetTester tester,
    String concern,
    List<String> topics,
  ) async {
    await tap(tester, find.text('Add a question'));
    final next = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.enterText(find.byType(TextField), concern);
    await tester.pump();
    await tap(tester, next);
    expect(find.text('What would you most like to ask about?'), findsOneWidget);
    for (final topic in topics) {
      await tap(tester, find.text(topic));
    }
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
  }

  testWidgets('a concern becomes a saved question for the appointment', (
    tester,
  ) async {
    service.reply = const PrepResult(
      PrepOutcome.question,
      'I get dizzy after my morning tablets. Why might this be happening?',
    );
    await pump(tester);
    expect(find.text('No questions yet.'), findsOneWidget);

    await describe(tester, 'dizzy after morning tablets', [
      'Why this may be happening',
      'What I should monitor',
    ]);
    expect(service.calls.single.concern, 'dizzy after morning tablets');
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(service.calls.single.topics, [
      AppointmentTopic.why,
      AppointmentTopic.monitor,
    ]);
    expect(service.calls.single.language, 'en');
    expect(find.text('A clearer way to ask it'), findsOneWidget);
    expect(find.textContaining('not medical advice'), findsOneWidget);

    await tap(tester, find.text('Save question'));
    expect(find.text('Saved for your next appointment'), findsOneWidget);
    expect(find.textContaining('You have 1 of 3 questions'), findsOneWidget);
    await tap(tester, find.text('Done'));

    expect(find.text('My appointment questions'), findsOneWidget);
    expect(find.text('Question 1'), findsOneWidget);
    expect(
      find.text(
        'I get dizzy after my morning tablets. Why might this be happening?',
      ),
      findsOneWidget,
    );
    expect(service.saved.single.concern, 'dizzy after morning tablets');
  });

  testWidgets('another wording sends the current one, and edits are kept', (
    tester,
  ) async {
    service.reply = const PrepResult(PrepOutcome.question, 'First wording?');
    await pump(tester);
    await describe(tester, 'ankles swell', ['What to do if it happens again']);

    service.reply = const PrepResult(PrepOutcome.question, 'Second wording?');
    await tap(tester, find.text('Try another wording'));
    expect(service.calls.last.previous, 'First wording?');
    expect(find.text('Second wording?'), findsOneWidget);

    await tap(tester, find.text('Edit'));
    await tester.enterText(find.byType(TextField), 'My own wording?');
    await tap(tester, find.text('Done editing'));
    await tap(tester, find.text('Save question'));
    expect(service.saved.single.question, 'My own wording?');
  });

  testWidgets('an urgent concern stops the card and saves nothing', (
    tester,
  ) async {
    service.reply = const PrepResult(PrepOutcome.emergency);
    await pump(tester);
    await describe(tester, 'I have chest pain now', ['Something else']);

    expect(find.text('If this is an emergency, get help now'), findsOneWidget);
    expect(find.textContaining('contact your care team soon'), findsOneWidget);
    expect(find.text('Save question'), findsNothing);
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    expect(find.text('No questions yet.'), findsOneWidget);
    expect(service.saved, isEmpty);
  });

  testWidgets('when the AI is busy the own words can still be saved', (
    tester,
  ) async {
    service.reply = const PrepResult(PrepOutcome.busy);
    await pump(tester);
    await describe(tester, 'Can I swim again?', ['Something else']);

    expect(find.text('We could not reword it right now'), findsOneWidget);
    expect(find.text('Can I swim again?'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tap(tester, find.text('Save question'));
    expect(service.saved.single.question, 'Can I swim again?');
  });

  /// Thẻ như ở cuối buổi tập, với ba câu đã lưu sẵn.
  Future<List<String>> pumpFullCard(WidgetTester tester) async {
    final events = <String>[];
    service.saved.addAll(const [
      AppointmentQuestion(id: 'a', question: 'First?', position: 0),
      AppointmentQuestion(id: 'b', question: 'Second?', position: 1),
      AppointmentQuestion(id: 'c', question: 'Third?', position: 2),
    ]);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppointmentPrepFlow(
              service: service,
              onSkip: () => events.add('skipped'),
              onFinished: (saved) => events.add('saved ${saved?.question}'),
              frame:
                  ({
                    required String title,
                    String? subtitle,
                    String? eyebrow,
                    required Widget child,
                    VoidCallback? onSkip,
                  }) => Column(
                    children: [
                      Text(title),
                      if (subtitle != null) Text(subtitle),
                      child,
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return events;
  }

  testWidgets('with three questions the card only reminds and moves on', (
    tester,
  ) async {
    final events = await pumpFullCard(tester);

    expect(
      find.text('You have 3 questions ready for your next appointment'),
      findsOneWidget,
    );
    for (final question in ['First?', 'Second?', 'Third?']) {
      expect(find.text(question), findsOneWidget);
    }
    expect(find.byType(TextField), findsNothing);
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    expect(events, ['skipped']);
    expect(service.calls, isEmpty);
  });

  testWidgets('a new question can take the place of an old one', (
    tester,
  ) async {
    final events = await pumpFullCard(tester);
    service.reply = const PrepResult(PrepOutcome.question, 'New second?');

    await tap(tester, find.text('Replace this one').at(1));
    expect(
      find.text('Your new question will replace: Second?'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'my ankles swell');
    await tester.pump();
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    await tap(tester, find.text('What I should monitor'));
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    await tap(tester, find.text('Save question'));

    expect(service.saved.map((q) => q.question), [
      'First?',
      'New second?',
      'Third?',
    ]);
    expect(find.textContaining('You have 3 of 3 questions'), findsOneWidget);
    await tap(tester, find.text('Done'));
    expect(events, ['saved New second?']);
  });

  testWidgets('going back from a replacement keeps all three', (tester) async {
    await pumpFullCard(tester);
    await tap(tester, find.text('Replace this one').first);
    await tap(tester, find.text('Back'));
    expect(
      find.text('You have 3 questions ready for your next appointment'),
      findsOneWidget,
    );
    expect(service.saved, hasLength(3));
  });

  testWidgets('three questions is the limit', (tester) async {
    service.saved.addAll([
      for (var i = 0; i < 3; i++)
        AppointmentQuestion(id: '$i', question: 'Question $i?', position: i),
    ]);
    await pump(tester);

    final add = find.widgetWithText(FilledButton, 'Add a question');
    expect(tester.widget<FilledButton>(add).onPressed, isNull);
    expect(find.textContaining('up to 3 questions'), findsOneWidget);
  });

  testWidgets('questions can be reordered, edited and removed', (tester) async {
    service.saved.addAll(const [
      AppointmentQuestion(id: 'a', question: 'First?', position: 0),
      AppointmentQuestion(id: 'b', question: 'Second?', position: 1),
    ]);
    await pump(tester);

    // Chỉ hiện nút dùng được: câu đầu không có "Move up", câu cuối không có
    // "Move down".
    expect(find.text('Move up'), findsOneWidget);
    expect(find.text('Move down'), findsOneWidget);
    await tap(tester, find.text('Move down'));
    expect(service.saved.map((q) => q.id), ['b', 'a']);
    expect(find.text('Moved to question 2'), findsOneWidget);
    final first = tester.getTopLeft(find.text('Second?'));
    expect(first.dy, lessThan(tester.getTopLeft(find.text('First?')).dy));

    await tap(tester, find.widgetWithText(TextButton, 'Edit').first);
    await tester.enterText(find.byType(TextField), 'Second, clearer?');
    await tap(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(find.text('Second, clearer?'), findsOneWidget);

    // Xoá phải hỏi lại: Cancel không xoá gì, Remove trong hộp thì xoá.
    await tap(tester, find.widgetWithText(TextButton, 'Remove').last);
    expect(find.text('Remove this question?'), findsOneWidget);
    await tap(tester, find.widgetWithText(TextButton, 'Cancel'));
    expect(find.text('First?'), findsOneWidget);
    await tap(tester, find.widgetWithText(TextButton, 'Remove').last);
    await tap(tester, find.widgetWithText(FilledButton, 'Remove'));
    expect(find.text('First?'), findsNothing);
    expect(service.saved.map((q) => q.id), ['b']);
  });

  testWidgets('while a change is saving, nothing else can be pressed', (
    tester,
  ) async {
    service.saved.addAll(const [
      AppointmentQuestion(id: 'a', question: 'First?', position: 0),
      AppointmentQuestion(id: 'b', question: 'Second?', position: 1),
      AppointmentQuestion(id: 'c', question: 'Third?', position: 2),
    ]);
    service.slow = Completer<void>();
    await pump(tester);

    // Thanh chờ chạy mãi tới khi lưu xong, nên chỉ pump từng khung hình.
    await tester.tap(find.text('Move down').first);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    for (final label in ['Move up', 'Move down', 'Edit', 'Remove']) {
      for (final button in tester.widgetList<TextButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is TextButton),
        ),
      )) {
        expect(button.onPressed, isNull, reason: label);
      }
    }
    service.reorders = 0;
    await tester.tap(find.text('Move down').first, warnIfMissed: false);
    await tester.pump();
    expect(service.reorders, 0);

    service.slow!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(service.saved.map((q) => q.id), ['b', 'a', 'c']);
  });

  testWidgets('Vietnamese and 200 percent text fit on a phone', (tester) async {
    service.reply = const PrepResult(
      PrepOutcome.question,
      'Tôi hay bị chóng mặt sau khi uống thuốc buổi sáng. Tại sao điều này có thể xảy ra?',
    );
    await pump(tester, textScale: 2, locale: 'vi');
    await tap(tester, find.text('Thêm câu hỏi'));
    await tester.enterText(find.byType(TextField), 'chóng mặt buổi sáng');
    await tester.pump();
    await tap(tester, find.widgetWithText(FilledButton, 'Tiếp tục'));
    await tap(tester, find.text('Vì sao điều này có thể xảy ra'));
    await tap(tester, find.widgetWithText(FilledButton, 'Tiếp tục'));

    expect(service.calls.single.language, 'vi');
    expect(find.text('Cách hỏi rõ ràng hơn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Call {
  _Call(this.concern, this.topics, this.language, this.previous);
  final String concern;
  final List<AppointmentTopic> topics;
  final String language;
  final String? previous;
}

class _FakeAppointments implements AppointmentService {
  PrepResult reply = const PrepResult(PrepOutcome.error);
  final calls = <_Call>[];
  final saved = <AppointmentQuestion>[];
  var _next = 0;

  /// Khi có: reorder chờ tới khi nó xong, để thử trạng thái đang lưu.
  Completer<void>? slow;
  var reorders = 0;

  @override
  Future<List<AppointmentQuestion>> load() async => List.of(saved);

  @override
  Future<PrepResult> rephrase({
    required String concern,
    required List<AppointmentTopic> topics,
    required String language,
    String? previous,
  }) async {
    calls.add(_Call(concern, topics, language, previous));
    return reply;
  }

  @override
  Future<AppointmentQuestion> add({
    required String question,
    String concern = '',
    List<AppointmentTopic> topics = const [],
  }) async {
    final added = AppointmentQuestion(
      id: 'new${_next++}',
      question: question,
      concern: concern,
      topics: topics,
      position: saved.length,
    );
    saved.add(added);
    return added;
  }

  @override
  Future<void> update(String id, String question) async {
    final index = saved.indexWhere((q) => q.id == id);
    saved[index] = saved[index].copyWith(question: question);
  }

  @override
  Future<void> remove(String id) async => saved.removeWhere((q) => q.id == id);

  @override
  Future<void> reorder(List<AppointmentQuestion> ordered) async {
    reorders++;
    await slow?.future;
    saved
      ..clear()
      ..addAll([for (final (i, q) in ordered.indexed) q.copyWith(position: i)]);
  }
}
