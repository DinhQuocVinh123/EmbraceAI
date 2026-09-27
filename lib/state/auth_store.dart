import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/account_session.dart';
import '../services/credential_codec.dart';

class AuthStore extends ChangeNotifier {
  AuthStore({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client {
    _subscription = _client.auth.onAuthStateChange.listen((event) {
      if (!_manualFlow) unawaited(_handleAuthChange(event.session?.user));
    });
    unawaited(_restoreSession());
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _subscription;

  AccountSession? _session;
  bool _loading = true;
  bool _busy = false;
  bool _manualFlow = false;
  String? _error;

  AccountSession? get session => _session;
  bool get isLoading => _loading;
  bool get isBusy => _busy;
  String? get error => _error;

  Future<void> _restoreSession() async {
    await _handleAuthChange(_client.auth.currentUser);
  }

  Future<void> _handleAuthChange(User? user) async {
    _loading = true;
    notifyListeners();
    try {
      if (user == null) {
        _session = null;
      } else {
        _session = await _loadSession(user);
        if (_session == null) {
          await _activateParticipantFromLink();
          _session = await _loadSession(user);
        }
        if (_session == null) {
          _error = 'This account is not active for EmbraceAI.';
          await _client.auth.signOut();
        }
      }
    } on PostgrestException {
      _error = 'The access service could not be reached.';
      _session = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _activateParticipantFromLink() async {
    try {
      await _client.rpc('activate_participant');
    } on PostgrestException {
      // Non-participant and inactive accounts are handled by the caller.
    }
  }

  Future<void> signInParticipant({
    required String participantCode,
    required String accessKey,
  }) async {
    final code = CredentialCodec.normalizeCode(participantCode);
    final key = CredentialCodec.normalizeAccessKey(accessKey);
    if (code.length != 10 || key.length != 16) {
      _setError('Check the Participant ID and access key, then try again.');
      return;
    }

    await _runManual(() async {
      await _client.auth.signOut();
      final response = await _client.auth.signInWithPassword(
        email: CredentialCodec.participantEmail(code),
        password: key,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFlowException('The access details are invalid.');
      }
      await _client.rpc('activate_participant');
      final loaded = await _loadSession(user);
      if (loaded == null || loaded.isStaff) {
        await _client.auth.signOut();
        throw const AuthFlowException(
          'This participant account is expired or inactive.',
        );
      }
      _session = loaded;
    });
  }

  Future<void> signInStaff({
    required String email,
    required String password,
  }) async {
    await _runManual(() async {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      final loaded = user == null ? null : await _loadSession(user);
      if (loaded == null || !loaded.isStaff) {
        await _client.auth.signOut();
        throw const AuthFlowException(
          'This account does not have staff portal access.',
        );
      }
      _session = loaded;
    });
  }

  Future<AccountSession?> _loadSession(User user) async {
    final staff = await _client
        .from('staff_profiles')
        .select('role, active')
        .eq('user_id', user.id)
        .maybeSingle();
    if (staff != null && staff['active'] == true) {
      final role = switch (staff['role']) {
        'admin' => AccountRole.admin,
        'coordinator' => AccountRole.coordinator,
        _ => AccountRole.researcher,
      };
      return AccountSession(uid: user.id, role: role);
    }

    final participant = await _client
        .from('participants')
        .select('participant_code, status, expires_at')
        .eq('auth_user_id', user.id)
        .maybeSingle();
    if (participant == null || participant['status'] != 'active') return null;
    final expiresAt = DateTime.tryParse(
      participant['expires_at'] as String? ?? '',
    );
    if (expiresAt != null && expiresAt.isBefore(DateTime.now().toUtc())) {
      return null;
    }
    return AccountSession(
      uid: user.id,
      role: AccountRole.participant,
      participantCode: participant['participant_code'] as String,
    );
  }

  Future<void> signOut() async {
    _session = null;
    _error = null;
    await _client.auth.signOut();
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> _runManual(Future<void> Function() action) async {
    _busy = true;
    _manualFlow = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on AuthFlowException catch (error) {
      _error = error.message;
    } on AuthException catch (error) {
      _error = _friendlyAuthError(error);
    } on PostgrestException {
      _error = 'The access service could not be reached. Please try again.';
    } finally {
      _manualFlow = false;
      _busy = false;
      _loading = false;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  static String _friendlyAuthError(AuthException error) => switch (error.code) {
    'over_request_rate_limit' || 'over_email_send_rate_limit' =>
      'Too many attempts. Wait a moment before trying again.',
    'user_banned' => 'This account has been suspended.',
    'invalid_credentials' => 'The access details are invalid.',
    _ => 'The credentials could not be verified.',
  };

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);
  final String message;
}
