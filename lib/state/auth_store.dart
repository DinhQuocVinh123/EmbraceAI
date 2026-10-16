import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/address_bar.dart';
import '../models/account_session.dart';
import '../services/credential_codec.dart';

/// Lỗi đăng nhập dưới dạng mã. Màn hình chọn câu theo ngôn ngữ đang dùng
/// (`authErrorText` trong lib/l10n/labels.dart); cổng nhân viên luôn tiếng Anh.
enum AuthErrorKind {
  linkExpired,
  accountNotActive,
  qrSignedOutOther,
  serviceUnreachable,
  serviceUnreachableRetry,
  checkDetails,
  pageForOther,
  invalidDetails,
  participantInactive,
  qrOtherNotOpened,
  noStaffAccess,
  tooManyAttempts,
  suspended,
  notVerified,
}

class AuthError {
  const AuthError(this.kind, {this.participant});

  final AuthErrorKind kind;

  /// Mã người tham gia của link QR (EA-XXXX-XXXX), với các lỗi nhắc đến nó.
  final String? participant;
}

class AuthStore extends ChangeNotifier {
  AuthStore({SupabaseClient? client, Uri? initialUri})
    : _client = client ?? Supabase.instance.client,
      _expectedParticipantCode = participantCodeFromUri(initialUri ?? Uri.base),
      _signInTokenHash = signInTokenFromUri(initialUri ?? Uri.base),
      _signInLink = signInLinkFromUri(initialUri ?? Uri.base) {
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

  /// Link dùng lại được `?link=EA1234ABCD.<mã>`: mỗi người tham gia một link,
  /// sống tới khi tài khoản hết hạn hoặc nhân viên đổi link. Máy chủ đổi nó
  /// thành một mã đăng nhập một lần, rồi đăng nhập như link một lần ở trên.
  final String? _signInLink;
  late final StreamSubscription<AuthState> _subscription;

  AccountSession? _session;
  bool _loading = true;
  bool _busy = false;
  bool _manualFlow = false;
  AuthError? _error;

  AccountSession? get session => _session;
  bool get isLoading => _loading;
  bool get isBusy => _busy;
  AuthError? get error => _error;

  Future<void> _restoreSession() async {
    var tokenHash = _signInTokenHash;
    if (_signInLink case final link?) {
      // Mã bí mật không ở lại trên thanh địa chỉ, dù đăng nhập được hay không.
      removeQueryParameter('link');
      try {
        final response = await _client.functions.invoke(
          'link-sign-in',
          body: {'link': link},
        );
        final data = response.data;
        tokenHash = data is Map ? data['tokenHash'] as String? : null;
      } catch (_) {
        tokenHash = null;
      }
      if (tokenHash == null) {
        // Link đã bị đổi hoặc tài khoản hết hạn. Nếu máy vẫn còn phiên đăng
        // nhập thì cứ dùng tiếp, không báo lỗi.
        if (_client.auth.currentUser == null) {
          _error = const AuthError(AuthErrorKind.linkExpired);
        }
        await _handleAuthChange(_client.auth.currentUser);
        return;
      }
    }
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
          _error = const AuthError(AuthErrorKind.linkExpired);
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
          _error = const AuthError(AuthErrorKind.accountNotActive);
          await _client.auth.signOut();
        } else if (!_matchesQrParticipant(loaded)) {
          _session = null;
          _error = AuthError(
            AuthErrorKind.qrSignedOutOther,
            participant: _displayExpectedParticipant(),
          );
          await _client.auth.signOut();
        } else {
          _session = loaded;
          _error = null;
        }
      }
    } on PostgrestException {
      _error = const AuthError(AuthErrorKind.serviceUnreachable);
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
      _setError(const AuthError(AuthErrorKind.checkDetails));
      return;
    }
    if (_expectedParticipantCode case final expected? when code != expected) {
      _setError(
        AuthError(
          AuthErrorKind.pageForOther,
          participant: _displayExpectedParticipant(),
        ),
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
        throw const AuthFlowException(AuthError(AuthErrorKind.invalidDetails));
      }
      await _client.rpc('activate_participant');
      final loaded = await _loadSession(user);
      if (loaded == null || loaded.isStaff) {
        await _client.auth.signOut();
        throw const AuthFlowException(
          AuthError(AuthErrorKind.participantInactive),
        );
      }
      if (!_matchesQrParticipant(loaded)) {
        await _client.auth.signOut();
        throw AuthFlowException(
          AuthError(
            AuthErrorKind.qrOtherNotOpened,
            participant: _displayExpectedParticipant(),
          ),
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
        throw const AuthFlowException(AuthError(AuthErrorKind.noStaffAccess));
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
      _error = error.error;
    } on AuthException catch (error) {
      _error = _friendlyAuthError(error);
    } on PostgrestException {
      _error = const AuthError(AuthErrorKind.serviceUnreachableRetry);
    } finally {
      _manualFlow = false;
      _busy = false;
      _loading = false;
      notifyListeners();
    }
  }

  void _setError(AuthError error) {
    _error = error;
    notifyListeners();
  }

  static AuthError _friendlyAuthError(AuthException error) =>
      AuthError(switch (error.code) {
        'over_request_rate_limit' ||
        'over_email_send_rate_limit' => AuthErrorKind.tooManyAttempts,
        'user_banned' => AuthErrorKind.suspended,
        'invalid_credentials' => AuthErrorKind.invalidDetails,
        _ => AuthErrorKind.notVerified,
      });

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

  @visibleForTesting
  static String? signInLinkFromUri(Uri uri) {
    final raw = uri.queryParameters['link']?.trim();
    if (raw == null) return null;
    return RegExp(r'^EA[A-Z0-9]{8}\.[A-Za-z0-9_-]{43}$').hasMatch(raw)
        ? raw
        : null;
  }

  bool _matchesQrParticipant(AccountSession session) {
    final expected = _expectedParticipantCode;
    return expected == null ||
        (!session.isStaff && session.participantCode == expected);
  }

  /// null khi không có mã: màn hình hiện "người tham gia này".
  String? _displayExpectedParticipant() {
    final code = _expectedParticipantCode;
    if (code == null || code.length != 10) return null;
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
  const AuthFlowException(this.error);
  final AuthError error;
}
