import 'dart:async';

import 'package:embrace_ai/core/theme.dart';
import 'package:embrace_ai/models/participant_record.dart';
import 'package:embrace_ai/models/study_assessment.dart';
import 'package:embrace_ai/screens/staff_dashboard_screen.dart';
import 'package:embrace_ai/services/staff_portal_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/screenshot_harness.dart';

void main() {
  setUpAll(ScreenshotHarness.loadFonts);

  final participants = [
    ParticipantRecord(
      code: 'EA23AB89XY',
      studyId: 'CARDIAC-MIND-01',
      group: 'Intervention',
      status: ParticipantStatus.active,
      consentStatus: ConsentStatus.accepted,
      sessionCount: 3,
      createdAt: DateTime(2026, 9, 20),
      lastActivityAt: DateTime(2026, 9, 27),
      expiresAt: DateTime(2026, 12, 20),
    ),
    ParticipantRecord(
      code: 'EA98CD76WV',
      studyId: 'CARDIAC-MIND-01',
      group: 'Control',
      status: ParticipantStatus.invited,
      consentStatus: ConsentStatus.pending,
      sessionCount: 0,
      createdAt: DateTime(2026, 9, 26),
      expiresAt: DateTime(2026, 12, 26),
    ),
  ];

  Future<void> pumpPortal(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
    StaffPortalService? service,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final baseTheme = AppTheme.light;
    await tester.pumpWidget(
      Provider<StaffPortalService>.value(
        value: service ?? _FakeStaffPortalService(participants),
        child: MaterialApp(
          theme: baseTheme.copyWith(
            textTheme: baseTheme.textTheme.apply(
              fontFamily: 'Segoe UI',
              fontFamilyFallback: const ['Segoe UI'],
            ),
            appBarTheme: baseTheme.appBarTheme.copyWith(
              titleTextStyle: baseTheme.appBarTheme.titleTextStyle?.copyWith(
                fontFamily: 'Segoe UI',
              ),
            ),
            chipTheme: baseTheme.chipTheme.copyWith(
              labelStyle: baseTheme.chipTheme.labelStyle?.copyWith(
                fontFamily: 'Segoe UI',
              ),
              secondaryLabelStyle: baseTheme.chipTheme.secondaryLabelStyle
                  ?.copyWith(fontFamily: 'Segoe UI'),
            ),
          ),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const StaffDashboardScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'desktop portal supports navigation, filtering and detail panel',
    (tester) async {
      await pumpPortal(tester, size: const Size(1440, 900));

      expect(find.text('Study overview'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(StaffDashboardScreen),
        matchesGoldenFile('goldens/staff_dashboard_desktop.png'),
      );

      await tester.tap(find.text('Participants').first);
      await tester.pumpAndSettle();
      expect(find.text('Search ID, study, or group'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'EA-23AB-89XY');
      await tester.pump();
      expect(find.text('1 of 2 participants'), findsOneWidget);

      await tester.tap(find.text('EA-23AB-89XY').last);
      await tester.pumpAndSettle();
      expect(find.text('Participant details'), findsOneWidget);
      expect(find.text('Reissue sign-in QR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mobile portal uses the compact navigation and layout', (
    tester,
  ) async {
    await pumpPortal(tester, size: const Size(400, 869));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Study overview'), findsOneWidget);
    expect(find.text('New participant'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(StaffDashboardScreen),
      matchesGoldenFile('goldens/staff_dashboard_mobile.png'),
    );
  });

  testWidgets('new participant uses controlled study group options', (
    tester,
  ) async {
    await pumpPortal(tester, size: const Size(1440, 900));

    await tester.tap(find.text('New participant'));
    await tester.pumpAndSettle();
    final finder = find.byWidgetPredicate(
      (widget) => widget is DropdownButton<String>,
    );
    expect(finder, findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(2));
    expect(find.text('Unassigned'), findsOneWidget);
    await tester.tap(find.text('Unassigned'));
    await tester.pumpAndSettle();
    expect(find.text('Intervention'), findsWidgets);
    expect(find.text('Control'), findsWidgets);
    await tester.tap(find.text('Control').last);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Control'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('90 days'));
    await tester.pumpAndSettle();
    expect(find.text('30 days'), findsWidgets);
    expect(find.text('180 days'), findsWidgets);
    await tester.tap(find.text('180 days').last);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('180 days'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a participant shows a blocking progress indicator', (
    tester,
  ) async {
    final service = _DelayedCreateStaffPortalService(participants);
    await pumpPortal(tester, size: const Size(1440, 900), service: service);

    await tester.tap(find.text('New participant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate access'));
    await tester.pump();

    expect(find.text('Creating participant...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    service.completeCreate();
    await tester.pumpAndSettle();
    expect(find.text('Creating participant...'), findsNothing);
    expect(find.text('Participant access created'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('participant invitation gives clear sign-in instructions', () {
    final invitation = buildParticipantInvitation(
      ParticipantAccessCard(
        code: 'EA-AKFR-D82N',
        accessKey: 'ABCD-EFGH-IJKL-MNPQ',
        loginUrl: 'https://example.test/secure-sign-in',
        expiresAt: DateTime(2026, 12, 28),
      ),
    );

    expect(invitation, contains('Your EMBRACE-AI access is ready.'));
    expect(invitation, contains('Participant ID: EA-AKFR-D82N'));
    expect(invitation, contains('Manual access key: ABCD-EFGH-IJKL-MNPQ'));
    expect(invitation, contains('To sign in, tap the secure link below:'));
    expect(invitation, contains('https://example.test/secure-sign-in'));
    expect(invitation, contains('can only be used once'));
    expect(invitation, contains('contact the research team'));
    expect(invitation, isNot(contains('One-time sign-in link:')));
  });

  test('reissued invitation does not mention a missing manual key', () {
    final invitation = buildParticipantInvitation(
      ParticipantAccessCard(
        code: 'EA-AKFR-D82N',
        loginUrl: 'https://example.test/secure-sign-in',
        expiresAt: DateTime(2026, 12, 28),
      ),
    );

    expect(invitation, isNot(contains('Manual access key')));
  });

  testWidgets('mobile portal remains usable at 200 percent text', (
    tester,
  ) async {
    await pumpPortal(tester, size: const Size(400, 869), textScale: 2);

    expect(find.text('Study overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeStaffPortalService extends StaffPortalService {
  _FakeStaffPortalService(this.participants)
    : super(
        client: SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final List<ParticipantRecord> participants;

  @override
  Stream<List<ParticipantRecord>> watchParticipants() =>
      Stream.value(participants);

  @override
  Stream<List<ParticipantSessionRecord>> watchSessions(String code) =>
      Stream.value(const []);

  @override
  Future<StudyResponseSummary> loadStudyResponses(String code) async =>
      const StudyResponseSummary();
}

class _DelayedCreateStaffPortalService extends _FakeStaffPortalService {
  _DelayedCreateStaffPortalService(super.participants);

  final _createCompleter = Completer<ParticipantAccessCard>();

  @override
  Future<ParticipantAccessCard> createParticipant({
    required String studyId,
    required String group,
    int validForDays = 90,
  }) => _createCompleter.future;

  void completeCreate() {
    _createCompleter.complete(
      ParticipantAccessCard(
        code: 'EA12CD34EF',
        accessKey: 'test-access-key',
        loginUrl: 'https://example.test/sign-in',
        expiresAt: DateTime(2026, 12, 28),
      ),
    );
  }
}
