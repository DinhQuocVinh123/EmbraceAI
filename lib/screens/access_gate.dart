import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/staff_portal_service.dart';
import '../state/auth_store.dart';
import 'home_screen.dart';
import 'participant_login_screen.dart';
import 'staff_dashboard_screen.dart';
import 'staff_login_screen.dart';

class AccessGate extends StatefulWidget {
  const AccessGate({super.key});

  @override
  State<AccessGate> createState() => _AccessGateState();
}

class _AccessGateState extends State<AccessGate> {
  bool _staffMode = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    if (auth.isLoading) return const _LoadingScreen();

    final session = auth.session;
    if (session?.isStaff == true) {
      return Provider(
        create: (_) => StaffPortalService(),
        child: const StaffDashboardScreen(),
      );
    }
    if (session != null) {
      return HomeScreen(
        participantCode: session.participantCode,
        onSignOut: auth.signOut,
      );
    }
    if (_staffMode) {
      return StaffLoginScreen(onBack: () => setState(() => _staffMode = false));
    }
    return ParticipantLoginScreen(
      onOpenStaffPortal: () => setState(() => _staffMode = true),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Checking access',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
