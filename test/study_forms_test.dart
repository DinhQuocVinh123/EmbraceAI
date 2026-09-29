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

  testWidgets('demographics form remains scrollable at 200 percent text', (
    tester,
  ) async {
    final service = _FakeStudyAssessmentService();
    await pump(
      tester,
      DemographicsScreen(
        service: service,
        onSubmitted: () async {},
        onSignOut: () async {},
      ),
      textScale: 2,
    );

    expect(find.text('Participant information'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save and continue'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    expect(find.text('Save and continue'), findsOneWidget);
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

    final finder = find.byWidgetPredicate(
      (widget) => widget is DropdownMenu<String>,
    );
    final dropdown = tester.widget<DropdownMenu<String>>(finder);
    expect(dropdown.enableFilter, isTrue);
    expect(dropdown.enableSearch, isTrue);
    expect(dropdown.dropdownMenuEntries.length, countries.length);
    expect(
      dropdown.dropdownMenuEntries.any((entry) => entry.value == 'Vietnam'),
      isTrue,
    );
    await tester.tap(finder);
    await tester.pumpAndSettle();
    final input = find.descendant(of: finder, matching: find.byType(TextField));
    await tester.enterText(input, 'Vietnam');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vietnam').last);
    await tester.pumpAndSettle();
    expect(find.text('Vietnam'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

    await tester.tap(find.text('Not at all').first);
    await tester.scrollUntilVisible(
      find.text('Save and next'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await tester.tap(find.text('Save and next'));
    await tester.pumpAndSettle();

    expect(service.lastAssessment?.gadResponses.first, 0);
    expect(service.lastSubmit, isFalse);
    expect(find.text('Your experience'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('Save and next'), findsOneWidget);
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
  bool acceptedConsent = false;
  final Completer<void>? consentCompleter;

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
