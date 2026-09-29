import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/account_session.dart';
import '../services/credential_codec.dart';

class AuthStore extends ChangeNotifier {
  AuthStore({SupabaseClient? client, Uri? initialUri})
    : _client = client ?? Supabase.instance.client,
      _expectedParticipantCode = participantCodeFromUri(initialUri ?? Uri.base),
      _signInTokenHash = signInTokenFromUri(initialUri ?? Uri.base) {
    _subscription = _client.auth.onAuthStateChange.listen((event) {
      if (!_manualFlow) unawaited(_handleAuthChange(event.session?.user));
    });
    unawaited(_restoreSession());
  }

  final SupabaseClient _client;
  final String? _expectedParticipantCode;

  /// Mã đăng nhập một lần trong link `?signin=...` mà nhân viên gửi cho người
  /// tham gia. Link nằm trên tên miền của app để người nhận đọc được; app tự
  /// xác thực mã với Supabase thay cho trang xác thực của Supabase.
  final String? _signInTokenHash;
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
    final tokenHash = _signInTokenHash;
    if (tokenHash != null) {
      // Tự xử lý sự kiện đăng nhập ở dưới, tránh chạy _handleAuthChange hai lần.
      _manualFlow = true;
      try {
        await _client.auth.verifyOTP(
          type: OtpType.magiclink,
          tokenHash: tokenHash,
        );
      } on AuthException {
        // Tải lại trang sau khi đã đăng nhập bằng link sẽ dùng lại mã cũ; lúc
        // đó phiên vẫn còn nên không báo lỗi.
        if (_client.auth.currentUser == null) {
          _error =
              'This sign-in link has expired or has already been used. Sign '
              'in with your Participant ID and access key, or ask the '
              'research team for a new link.';
        }
      } finally {
        _manualFlow = false;
      }
    }
    await _handleAuthChange(_client.auth.currentUser);
  }

  Future<void> _handleAuthChange(User? user) async {
    _loading = true;
    notifyListeners();
    try {
      if (user == null) {
        _session = null;
      } else {
        var loaded = await _loadSession(user);
        if (loaded == null) {
          await _activateParticipantFromLink();
          loaded = await _loadSession(user);
        }
        if (loaded == null) {
          _error = 'This account is not active for EmbraceAI.';
          await _client.auth.signOut();
        } else if (!_matchesQrParticipant(loaded)) {
          _session = null;
          _error =
              'This QR code is for ${_displayExpectedParticipant()}. '
              'A different saved account was signed out. Scan the QR code '
              'again to continue safely.';
          await _client.auth.signOut();
        } else {
          _session = loaded;
          _error = null;
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
    if (_expectedParticipantCode case final expected? when code != expected) {
      _setError(
        'This page was opened for ${_displayExpectedParticipant()}. '
        'Use that Participant ID or open the main app address again.',
      );
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
      if (!_matchesQrParticipant(loaded)) {
        await _client.auth.signOut();
        throw AuthFlowException(
          'This QR code is for ${_displayExpectedParticipant()}. '
          'The other account was not opened.',
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

  @visibleForTesting
  static String? participantCodeFromUri(Uri uri) {
    final raw = uri.queryParameters['participant'];
    if (raw == null) return null;
    final code = CredentialCodec.normalizeCode(raw);
    return RegExp(r'^EA[A-Z0-9]{8}$').hasMatch(code) ? code : null;
  }

  @visibleForTesting
  static String? signInTokenFromUri(Uri uri) {
    final raw = uri.queryParameters['signin']?.trim().toLowerCase();
    if (raw == null) return null;
    return RegExp(r'^[0-9a-f]{20,128}$').hasMatch(raw) ? raw : null;
  }

  bool _matchesQrParticipant(AccountSession session) {
    final expected = _expectedParticipantCode;
    return expected == null ||
        (!session.isStaff && session.participantCode == expected);
  }

  String _displayExpectedParticipant() {
    final code = _expectedParticipantCode;
    if (code == null || code.length != 10) return 'this participant';
    return '${code.substring(0, 2)}-${code.substring(2, 6)}-'
        '${code.substring(6)}';
  }

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
