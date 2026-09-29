import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_surface.dart';
import '../core/theme.dart';
import '../data/prefs_journal_repository.dart';
import '../data/session_sync_journal_repository.dart';
import '../services/staff_portal_service.dart';
import '../state/auth_store.dart';
import '../state/journal_store.dart';
import 'participant_login_screen.dart';
import 'participant_study_gate.dart';
import 'staff_dashboard_screen.dart';
import 'staff_login_screen.dart';

class AccessGate extends StatelessWidget {
  const AccessGate({super.key, this.surface = AppSurface.current});

  /// Bản app đang chạy. Mỗi bản chỉ mở phần của mình; tài khoản của bên kia
  /// được chỉ sang đúng địa chỉ thay vì mở vào.
  final AppSurface surface;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    if (auth.isLoading) return const _LoadingScreen();

    final session = auth.session;
    final isStaffSurface = surface == AppSurface.staff;

    if (session == null) {
      return isStaffSurface
          ? const StaffLoginScreen()
          : const ParticipantLoginScreen();
    }
    if (session.isStaff != isStaffSurface) {
      return _WrongPortalScreen(
        forStaff: session.isStaff,
        onSignOut: auth.signOut,
      );
    }
    if (session.isStaff) {
      return Provider(
        create: (_) => StaffPortalService(),
        child: const StaffDashboardScreen(),
      );
    }
    return ChangeNotifierProvider(
      key: ValueKey('journal-${session.uid}'),
      create: (_) => JournalStore(
        SessionSyncJournalRepository(
          local: PrefsJournalRepository(namespace: session.uid),
          legacy: PrefsJournalRepository(),
        ),
      )..load(),
      child: ParticipantStudyGate(
        participantCode: session.participantCode!,
        onSignOut: auth.signOut,
      ),
    );
  }
}

/// Tài khoản đã đăng nhập nhưng thuộc cổng kia, ví dụ nhân viên còn phiên cũ
/// trên địa chỉ của người tham gia từ trước khi tách hai cổng.
class _WrongPortalScreen extends StatelessWidget {
  const _WrongPortalScreen({required this.forStaff, required this.onSignOut});

  final bool forStaff;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = forStaff
        ? AppSurface.staffPortalUrl
        : AppSurface.participantAppUrl;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Icon(
                    forStaff
                        ? Icons.admin_panel_settings_outlined
                        : Icons.self_improvement,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  Gap.m,
                  Text(
                    forStaff
                        ? 'The staff portal has its own address'
                        : 'This is the staff portal',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  Gap.s,
                  Text(
                    forStaff
                        ? 'Staff accounts sign in at the address below.'
                        : 'Participants sign in to EmbraceAI at the address '
                              'below.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Gap.l,
                  SelectableText(
                    address,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Gap.l,
                  FilledButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
