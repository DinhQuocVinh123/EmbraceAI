import 'package:embrace_ai/core/app_surface.dart';
import 'package:embrace_ai/core/theme.dart';
import 'package:embrace_ai/models/account_session.dart';
import 'package:embrace_ai/screens/access_gate.dart';
import 'package:embrace_ai/screens/participant_login_screen.dart';
import 'package:embrace_ai/screens/staff_login_screen.dart';
import 'package:embrace_ai/state/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Hai bản web chỉ mở phần của mình; tài khoản của bên kia được chỉ sang
/// đúng địa chỉ thay vì mở vào.
void main() {
  Future<void> pumpGate(
    WidgetTester tester, {
    required AppSurface surface,
    AccountSession? session,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthStore>.value(
        value: _FakeAuthStore(session),
        child: MaterialApp(
          theme: AppTheme.light,
          home: AccessGate(surface: surface),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const participant = AccountSession(
    uid: 'p1',
    role: AccountRole.participant,
    participantCode: 'EA12CD34EF',
  );
  const staff = AccountSession(uid: 's1', role: AccountRole.coordinator);

  testWidgets('participant app shows only participant sign-in', (tester) async {
    await pumpGate(tester, surface: AppSurface.participant);

    expect(find.byType(ParticipantLoginScreen), findsOneWidget);
    expect(find.text('Staff portal'), findsNothing);
    expect(find.byType(StaffLoginScreen), findsNothing);
  });

  testWidgets('staff portal opens straight to staff sign-in', (tester) async {
    await pumpGate(tester, surface: AppSurface.staff);

    expect(find.byType(StaffLoginScreen), findsOneWidget);
    expect(find.byType(ParticipantLoginScreen), findsNothing);
    expect(find.byTooltip('Back to participant access'), findsNothing);
  });

  testWidgets('a staff session on the participant app is sent to the portal', (
    tester,
  ) async {
    await pumpGate(tester, surface: AppSurface.participant, session: staff);

    expect(find.text('The staff portal has its own address'), findsOneWidget);
    expect(find.text(AppSurface.staffPortalUrl), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('a participant session on the staff portal is sent back', (
    tester,
  ) async {
    await pumpGate(tester, surface: AppSurface.staff, session: participant);

    expect(find.text('This is the staff portal'), findsOneWidget);
    expect(find.text(AppSurface.participantAppUrl), findsOneWidget);
  });
}

class _FakeAuthStore extends ChangeNotifier implements AuthStore {
  _FakeAuthStore(this.session);

  @override
  final AccountSession? session;

  @override
  bool get isLoading => false;

  @override
  bool get isBusy => false;

  @override
  String? get error => null;

  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
