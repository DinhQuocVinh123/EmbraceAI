import 'dart:async';

import 'package:embrace_ai/core/theme.dart';
import 'package:embrace_ai/data/countries.dart';
import 'package:embrace_ai/models/consent.dart';
import 'package:embrace_ai/models/study_assessment.dart';
import 'package:embrace_ai/screens/demographics_screen.dart';
import 'package:embrace_ai/screens/final_assessment_screen.dart';
import 'package:embrace_ai/screens/participant_consent_screen.dart';
import 'package:embrace_ai/screens/participant_study_gate.dart';
import 'package:embrace_ai/services/study_assessment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(400, 869);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 869),
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  final countryDropdown = find.byWidgetPredicate(
    (widget) => widget is DropdownMenu<String>,
  );

  Future<void> pickCountry(WidgetTester tester, String country) async {
    await tester.tap(countryDropdown);
    await tester.pumpAndSettle();
    final input = find.descendant(
      of: countryDropdown,
      matching: find.byType(TextField),
    );
    await tester.enterText(input, country);
    await tester.pumpAndSettle();
    await tester.tap(find.text(country).last);
    await tester.pumpAndSettle();
  }

  /// Trả lời các câu trước câu nước sinh.
  Future<void> answerUntilCountry(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), '67');
    await tapText(tester, 'Next');
    await tester.tap(find.text('Female'));
    await tapText(tester, 'Next');
    await tester.tap(find.text('Asian'));
    await tapText(tester, 'Next');
  }

  testWidgets('demographics shows one question at a time at 200 percent text', (
    tester,
  ) async {
    await pump(
      tester,
      DemographicsScreen(
        service: _FakeStudyAssessmentService(),
        onSubmitted: () async {},
        onSignOut: () async {},
      ),
      textScale: 2,
    );

    expect(find.text('Participant information'), findsOneWidget);
    expect(find.text('Question 1 of 7'), findsOneWidget);
    // Nút Tiếp nằm cố định ở đáy, không phải cuộn tìm.
    await tapText(tester, 'Next');
    expect(find.text('Question 1 of 7'), findsOneWidget);
    // Ở cỡ chữ này ô nhập nằm dưới phần giới thiệu: cuộn tới để thấy lỗi.
    await tester.scrollUntilVisible(
      find.text('Enter age in years.'),
      200,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    expect(find.text('Enter age in years.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('country of birth uses a searchable country dropdown', (
    tester,
  ) async {
    await pump(
      tester,
      DemographicsScreen(
        service: _FakeStudyAssessmentService(),
        onSubmitted: () async {},
        onSignOut: () async {},
      ),
    );
    await answerUntilCountry(tester);

    final dropdown = tester.widget<DropdownMenu<String>>(countryDropdown);
    expect(dropdown.enableFilter, isTrue);
    expect(dropdown.enableSearch, isTrue);
    expect(dropdown.dropdownMenuEntries.length, countries.length);
    expect(
      dropdown.dropdownMenuEntries.any((entry) => entry.value == 'Vietnam'),
      isTrue,
    );
    await pickCountry(tester, 'Vietnam');
    expect(find.text('Vietnam'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demographics saves drafts, then submits after the review', (
    tester,
  ) async {
    final service = _FakeStudyAssessmentService();
    var submitted = false;
    await pump(
      tester,
      DemographicsScreen(
        service: service,
        onSubmitted: () async => submitted = true,
        onSignOut: () async {},
      ),
    );

    await answerUntilCountry(tester);
    expect(service.lastDemographics?.ageYears, 67);
    expect(service.lastDemographicsSubmit, isFalse);
    await pickCountry(tester, 'Vietnam');
    await tapText(tester, 'Next');
    await tester.tap(find.text('Prefer not to say'));
    await tapText(tester, 'Next');
    await tester.enterText(find.byType(TextField), 'Heart failure');
    await tapText(tester, 'Next');
    // Câu cuối không bắt buộc.
    await tapText(tester, 'Review answers');

    expect(find.text('Check your answers'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    // Sửa một câu thì quay thẳng về trang xem lại.
    await tester.tap(find.text('Change').first);
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of 7'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '68');
    await tapText(tester, 'Review answers');
    expect(find.text('68'), findsOneWidget);

    await tapText(tester, 'Save and continue');
    expect(service.lastDemographicsSubmit, isTrue);
    expect(service.lastDemographics?.ageYears, 68);
    expect(service.lastDemographics?.countryOfBirth, 'Vietnam');
    expect(service.lastDemographics?.cardiovascularDiagnosis, 'Heart failure');
    expect(submitted, isTrue);
  });

  testWidgets('consent requires every acknowledgement before continuing', (
    tester,
  ) async {
    final service = _FakeStudyAssessmentService();
    await pump(
      tester,
      ParticipantConsentScreen(
        service: service,
        onAccepted: () async {},
        onSignOut: () async {},
      ),
    );

    final button = find.widgetWithText(FilledButton, 'I consent and continue');
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    const statements = [
      'I have read and understood the information above.',
      'I understand that taking part is voluntary and that I may stop at any time.',
      'I understand that this relaxation exercise is not medical treatment.',
      'I consent to the research team collecting and using the information described above for this study.',
    ];
    for (final statement in statements) {
      final text = find.text(statement);
      await tester.scrollUntilVisible(
        text,
        statement == statements.first ? -300 : 300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 20,
      );
      await tester.tap(text);
      await tester.pump();
    }
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(service.acceptedConsent, isTrue);
  });

  testWidgets('consent shows a blocking progress indicator while saving', (
    tester,
  ) async {
    final consentCompleter = Completer<void>();
    final service = _FakeStudyAssessmentService(
      consentCompleter: consentCompleter,
    );
    var accepted = false;
    await pump(
      tester,
      ParticipantConsentScreen(
        service: service,
        onAccepted: () async {
          accepted = true;
        },
        onSignOut: () async {},
      ),
    );

    const statements = [
      'I have read and understood the information above.',
      'I understand that taking part is voluntary and that I may stop at any time.',
      'I understand that this relaxation exercise is not medical treatment.',
      'I consent to the research team collecting and using the information described above for this study.',
    ];
    for (final statement in statements) {
      final text = find.text(statement);
      await tester.scrollUntilVisible(
        text,
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 20,
      );
      await tester.tap(text);
      await tester.pump();
    }
    final button = find.widgetWithText(FilledButton, 'I consent and continue');
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    await tester.tap(button);
    await tester.pump();

    expect(find.text('Saving your consent...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(accepted, isFalse);

    consentCompleter.complete();
    await tester.pumpAndSettle();
    expect(find.text('Saving your consent...'), findsNothing);
    expect(service.acceptedConsent, isTrue);
    expect(accepted, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('consent spinner remains until refreshed progress changes screen', (
    tester,
  ) async {
    final service = _GateStudyAssessmentService();
    await pump(
      tester,
      Provider<StudyAssessmentService>.value(
        value: service,
        child: const ParticipantStudyGate(
          participantCode: 'EA23AB89XY',
          onSignOut: _noOpSignOut,
        ),
      ),
    );

    const statements = [
      'I have read and understood the information above.',
      'I understand that taking part is voluntary and that I may stop at any time.',
      'I understand that this relaxation exercise is not medical treatment.',
      'I consent to the research team collecting and using the information described above for this study.',
    ];
    for (final statement in statements) {
      final text = find.text(statement);
      await tester.scrollUntilVisible(
        text,
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 20,
      );
      await tester.tap(text);
      await tester.pump();
    }
    final button = find.widgetWithText(FilledButton, 'I consent and continue');
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    await tester.tap(button);
    await tester.pump();

    expect(service.acceptedConsent, isTrue);
    expect(find.text('Saving your consent...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Saving your consent...'), findsOneWidget);

    service.completeRefresh();
    await tester.pumpAndSettle();
    expect(find.text('Saving your consent...'), findsNothing);
    expect(find.text('Participant information'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('final questionnaire saves item responses as a draft', (
    tester,
  ) async {
    final service = _FakeStudyAssessmentService();
    await pump(
      tester,
      FinalAssessmentScreen(
        service: service,
        onSubmitted: () async {},
        onDefer: () {},
        onSignOut: () async {},
      ),
    );

    await tester.tap(find.text('Not at all'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(service.lastAssessment?.gadResponses.first, 0);
    expect(service.lastSubmit, isFalse);
    expect(find.text('2. Difficulty controlling worrying'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every GAD-7 item shows the scale instruction verbatim', (
    tester,
  ) async {
    await pump(
      tester,
      FinalAssessmentScreen(
        service: _FakeStudyAssessmentService(),
        onSubmitted: () async {},
        onDefer: () {},
        onSignOut: () async {},
      ),
    );

    const stem =
        'Over the last 2 weeks, how often have you been bothered by the '
        'following problems?';
    for (var item = 1; item <= 7; item++) {
      expect(find.text('Question $item of 20'), findsOneWidget);
      expect(find.text(stem), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(
      find.text(
        'How would you rate your overall emotional well-being right now?',
      ),
      findsOneWidget,
    );
  });

  testWidgets('final questionnaire actions stack at 200 percent text', (
    tester,
  ) async {
    await pump(
      tester,
      FinalAssessmentScreen(
        service: _FakeStudyAssessmentService(),
        onSubmitted: () async {},
        onDefer: () {},
        onSignOut: () async {},
      ),
      textScale: 2,
    );

    expect(find.text('Do this later'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeStudyAssessmentService extends StudyAssessmentService {
  _FakeStudyAssessmentService({this.consentCompleter})
    : super(
        client: SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  ProgramAssessmentAnswers? lastAssessment;
  bool? lastSubmit;
  DemographicAnswers? lastDemographics;
  bool? lastDemographicsSubmit;
  bool acceptedConsent = false;
  final Completer<void>? consentCompleter;

  @override
  Future<void> saveDemographics(
    DemographicAnswers answers, {
    required bool submit,
  }) async {
    lastDemographics = answers;
    lastDemographicsSubmit = submit;
  }

  @override
  Future<void> acceptConsent() async {
    await consentCompleter?.future;
    acceptedConsent = true;
  }

  @override
  Future<DemographicAnswers?> loadDemographics() async => null;

  @override
  Future<ProgramAssessmentAnswers?> loadAssessment(String timepoint) async =>
      null;

  @override
  Future<void> saveAssessment(
    ProgramAssessmentAnswers answers, {
    String timepoint = 'final',
    required bool submit,
  }) async {
    lastAssessment = answers;
    lastSubmit = submit;
  }
}

class _GateStudyAssessmentService extends _FakeStudyAssessmentService {
  final _refreshCompleter = Completer<StudyProgress>();

  @override
  Stream<StudyProgress> watchProgress(String participantCode) => Stream.value(
    const StudyProgress(
      consentStatus: ConsentStatus.pending,
      demographicsStatus: FormCompletionStatus.notStarted,
      finalAssessmentStatus: FinalAssessmentStatus.notDue,
    ),
  );

  @override
  Future<StudyProgress> loadProgress(String participantCode) =>
      _refreshCompleter.future;

  void completeRefresh() {
    _refreshCompleter.complete(
      const StudyProgress(
        consentStatus: ConsentStatus.accepted,
        demographicsStatus: FormCompletionStatus.notStarted,
        finalAssessmentStatus: FinalAssessmentStatus.notDue,
      ),
    );
  }
}

Future<void> _noOpSignOut() async {}
