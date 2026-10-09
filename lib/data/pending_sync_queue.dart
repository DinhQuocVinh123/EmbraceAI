import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Một lệnh gửi lên máy chủ (tên hàm RPC + tham số) chưa gửi được.
class PendingSyncCall {
  const PendingSyncCall(this.function, this.params);

  final String function;
  final Map<String, Object?> params;

  String? get clientEntryId => params['p_client_entry_id'] as String?;

  Map<String, Object?> toMap() => {'function': function, 'params': params};

  factory PendingSyncCall.fromMap(Map<String, Object?> map) => PendingSyncCall(
    map['function'] as String,
    Map<String, Object?>.from(map['params'] as Map),
  );
}

/// Lệnh chưa gửi được vì mất mạng, giữ trên máy để gửi lại lần sau.
///
/// Mỗi lệnh mang sẵn client_entry_id nên gửi lại nhiều lần cũng không tạo bản
/// ghi trùng. Tách theo tài khoản: trên máy dùng chung, lệnh của người này
/// không bao giờ được gửi bằng phiên của người khác.
class PendingSyncQueue {
  PendingSyncQueue({SharedPreferences? prefs, required String namespace})
    : _prefs = prefs,
      _namespace = namespace;

  /// Giới hạn để hàng đợi không phình mãi khi máy offline rất lâu.
  static const maxLength = 200;

  final String _namespace;
  SharedPreferences? _prefs;

  String get _key => 'journal.$_namespace.pendingSync';

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<List<PendingSyncCall>> fetchAll() async {
    final raw = (await _store).getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    return [
      for (final item in jsonDecode(raw) as List<dynamic>)
        PendingSyncCall.fromMap(Map<String, Object?>.from(item as Map)),
    ];
  }

  Future<void> add(PendingSyncCall call) async {
    final all = [...await fetchAll(), call];
    await replaceAll(
      all.length > maxLength ? all.sublist(all.length - maxLength) : all,
    );
  }

  Future<void> replaceAll(List<PendingSyncCall> calls) async {
    final prefs = await _store;
    if (calls.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(
      _key,
      jsonEncode([for (final call in calls) call.toMap()]),
    );
  }
}
