import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal_entry.dart';
import '../models/mood.dart';
import 'journal_repository.dart';
import 'pending_sync_queue.dart';

/// Phần máy chủ mà kho nhật ký dùng tới. Tách ra để test được logic đồng bộ
/// mà không cần Supabase thật.
abstract class SessionJournalRemote {
  bool get isSignedIn;

  Future<List<Map<String, dynamic>>> fetchSessions();

  Future<List<Map<String, dynamic>>> fetchPrivateEntries();

  Future<void> rpc(String function, Map<String, Object?> params);
}

class SupabaseSessionJournalRemote implements SessionJournalRemote {
  SupabaseSessionJournalRemote(this._client);

  final SupabaseClient _client;

  @override
  bool get isSignedIn => _client.auth.currentUser != null;

  @override
  Future<List<Map<String, dynamic>>> fetchSessions() => _client
      .from('sessions')
      .select(
        'client_entry_id, local_entry_id, occurred_at, '
        'client_updated_at, mood_after, journal_deleted_at',
      )
      .order('occurred_at', ascending: false);

  @override
  Future<List<Map<String, dynamic>>> fetchPrivateEntries() => _client
      .from('participant_journal_entries')
      .select(
        'client_entry_id, occurred_at, client_updated_at, '
        'mood_after, note, tags',
      )
      .order('occurred_at', ascending: false);

  @override
  Future<void> rpc(String function, Map<String, Object?> params) async {
    await _client.rpc(function, params: params);
  }
}

class SessionSyncJournalRepository
    implements JournalRepository, SessionRecorder {
  /// `local_entry_id` của buổi tập không lưu vào nhật ký. Id trong máy bắt
  /// đầu từ 1, nên 0 không trùng mục nào và đánh dấu buổi đó để ẩn khỏi
  /// nhật ký trên mọi máy.
  static const unsavedLocalEntryId = 0;

  static const _recordSession = 'record_session';
  static const _deleteSessionJournal = 'delete_session_journal';

  SessionSyncJournalRepository({
    required JournalRepository local,
    required PendingSyncQueue pending,
    JournalRepository? legacy,
    SupabaseClient? client,
    SessionJournalRemote? remote,
  }) : _local = local,
       _pending = pending,
       _legacy = legacy,
       _remote =
           remote ??
           SupabaseSessionJournalRemote(client ?? Supabase.instance.client);

  final JournalRepository _local;
  final PendingSyncQueue _pending;
  final JournalRepository? _legacy;
  final SessionJournalRemote _remote;

  Future<void>? _flushing;

  @override
  Future<List<JournalEntry>> fetchAll() async {
    var localEntries = await _local.fetchAll();
    final legacyEntries = await _legacy?.fetchAll() ?? const <JournalEntry>[];
    if (!_remote.isSignedIn) return localEntries;

    await _flushPending();
    // Lệnh xoá còn kẹt trong hàng đợi thì máy chủ vẫn giữ ghi chú: không được
    // kéo nó về lại.
    final pendingDeletes = {
      for (final call in await _pending.fetchAll())
        if (call.function == _deleteSessionJournal) ?call.clientEntryId,
    };

    try {
      final results = await Future.wait([
        _remote.fetchSessions(),
        _remote.fetchPrivateEntries(),
      ]);
      final rows = results[0];
      final privateRows = results[1];
      final privateBySyncId = <String, Map<String, dynamic>>{
        for (final row in privateRows)
          if (row['client_entry_id'] case final String syncId) syncId: row,
      };

      // Mục đã bị xoá trên máy khác thì xoá luôn bản trên máy này.
      final deletedSyncIds = {
        ...pendingDeletes,
        for (final row in rows)
          if (row['journal_deleted_at'] != null)
            if (row['client_entry_id'] case final String syncId) syncId,
      };
      final keptEntries = <JournalEntry>[];
      for (final entry in localEntries) {
        final id = entry.id;
        if (id != null && deletedSyncIds.contains(entry.syncId)) {
          await _local.delete(id);
        } else {
          keptEntries.add(entry);
        }
      }
      localEntries = keptEntries;

      final merged = <JournalEntry>[];
      final matchedLocalIds = <int>{};
      final remoteSyncIds = <String>{};

      for (final row in rows) {
        final syncId = row['client_entry_id'] as String?;
        if (syncId != null) remoteSyncIds.add(syncId);
        if (deletedSyncIds.contains(syncId)) continue;
        final privateRow = syncId == null ? null : privateBySyncId[syncId];
        // Người dùng đã chọn không lưu buổi này vào nhật ký: chỉ tính cho
        // nghiên cứu, không hiện trong nhật ký.
        if ((row['local_entry_id'] as num?)?.toInt() == unsavedLocalEntryId &&
            privateRow == null) {
          continue;
        }
        final occurredAt = DateTime.parse(
          row['occurred_at'] as String,
        ).toLocal();
        final localEntryId = (row['local_entry_id'] as num?)?.toInt();
        JournalEntry? localMatch = _matchingEntry(
          localEntries,
          syncId: syncId,
          localEntryId: localEntryId,
          occurredAt: occurredAt,
        );
        if (localMatch == null) {
          final legacyMatch = _matchingEntry(
            legacyEntries,
            syncId: syncId,
            localEntryId: localEntryId,
            occurredAt: occurredAt,
          );
          if (legacyMatch != null && syncId != null) {
            localMatch = await _local.insert(
              JournalEntry(
                syncId: syncId,
                mood: legacyMatch.mood,
                note: legacyMatch.note,
                tags: legacyMatch.tags,
                createdAt: legacyMatch.createdAt,
                updatedAt: legacyMatch.updatedAt,
              ),
            );
          }
        }

        if (localMatch != null) {
          final id = localMatch.id;
          if (id != null) matchedLocalIds.add(id);
          if (localMatch.syncId == null && syncId != null) {
            localMatch = localMatch.copyWith(syncId: syncId);
            await _local.update(localMatch);
          }
          if (privateRow != null &&
              _remoteUpdatedAt(privateRow).isAfter(localMatch.updatedAt)) {
            localMatch = _entryFromRemote(privateRow, localId: localMatch.id);
            await _local.update(localMatch);
          } else {
            await _syncSession(localMatch);
          }
          merged.add(localMatch);
          continue;
        }

        if (privateRow != null) {
          final saved = await _local.insert(_entryFromRemote(privateRow));
          if (saved.id != null) matchedLocalIds.add(saved.id!);
          merged.add(saved);
          continue;
        }

        final score = (row['mood_after'] as num?)?.toInt();
        merged.add(
          JournalEntry(
            syncId: syncId,
            isRemoteSummary: true,
            mood: score == null ? null : Mood.fromScore(score),
            note: 'Session completed on another device.',
            tags: const ['Session', 'Synced'],
            createdAt: occurredAt,
            updatedAt: DateTime.parse(
              row['client_updated_at'] as String,
            ).toLocal(),
          ),
        );
      }

      for (final entry in localEntries) {
        if (entry.id != null && matchedLocalIds.contains(entry.id)) continue;
        merged.add(entry);
        if (entry.tags.contains('Session') &&
            entry.syncId != null &&
            !remoteSyncIds.contains(entry.syncId)) {
          await _syncSession(entry);
        }
      }

      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged;
    } catch (_) {
      // Local data remains usable while offline or during a backend rollout.
      return localEntries;
    }
  }

  @override
  Future<JournalEntry> insert(JournalEntry entry) async {
    final prepared = entry.tags.contains('Session') && entry.syncId == null
        ? entry.copyWith(syncId: _newUuid())
        : entry;
    final saved = await _local.insert(prepared);
    if (saved.tags.contains('Session')) await _syncSession(saved);
    return saved;
  }

  @override
  Future<void> update(JournalEntry entry) async {
    final prepared = entry.tags.contains('Session') && entry.syncId == null
        ? entry.copyWith(syncId: _newUuid())
        : entry;
    await _local.update(prepared);
    if (prepared.tags.contains('Session')) await _syncSession(prepared);
  }

  /// Mục gắn với buổi tập thì xoá luôn ghi chú trên máy chủ và để lại dấu "đã
  /// xoá" cho các máy khác. Buổi tập vẫn được tính cho nghiên cứu.
  @override
  Future<void> delete(int id) async {
    final entries = await _local.fetchAll();
    final entry = entries.where((e) => e.id == id).firstOrNull;
    await _local.delete(id);
    final syncId = entry?.syncId;
    if (entry == null || syncId == null || !entry.tags.contains('Session')) {
      return;
    }
    await _send(
      PendingSyncCall(_deleteSessionJournal, {
        'p_client_entry_id': syncId,
        'p_occurred_at': entry.createdAt.toUtc().toIso8601String(),
        'p_client_updated_at': DateTime.now().toUtc().toIso8601String(),
        'p_mood_after': entry.mood?.score,
        'p_reflection_provided': entry.note.trim().isNotEmpty,
      }),
    );
  }

  Future<void> _syncSession(JournalEntry entry) async {
    if (!_remote.isSignedIn || entry.id == null || entry.syncId == null) {
      return;
    }
    try {
      await _remote.rpc('sync_session_journal', {
        'p_local_entry_id': entry.id,
        'p_client_entry_id': entry.syncId,
        'p_occurred_at': entry.createdAt.toUtc().toIso8601String(),
        'p_client_updated_at': entry.updatedAt.toUtc().toIso8601String(),
        'p_mood_after': entry.mood?.score,
        'p_note': entry.note,
        'p_tags': entry.tags,
      });
    } catch (_) {
      // The on-device journal remains the source of truth if sync is offline.
    }
  }

  /// Mất mạng lúc kết thúc buổi tập thì lệnh nằm chờ trong hàng đợi và được
  /// gửi lại lần mở app sau, nên buổi tập không bị mất khỏi số liệu.
  @override
  Future<void> recordUnsavedSession({
    required DateTime occurredAt,
    Mood? moodAfter,
    required bool reflectionProvided,
  }) async {
    await _send(
      PendingSyncCall(_recordSession, {
        'p_local_entry_id': unsavedLocalEntryId,
        'p_client_entry_id': _newUuid(),
        'p_occurred_at': occurredAt.toUtc().toIso8601String(),
        'p_client_updated_at': DateTime.now().toUtc().toIso8601String(),
        'p_mood_after': moodAfter?.score,
        'p_reflection_provided': reflectionProvided,
      }),
    );
  }

  /// Ghi lệnh vào hàng đợi trước rồi mới gửi ở nền, để màn hình không phải
  /// chờ mạng và tắt app giữa chừng cũng không mất lệnh.
  Future<void> _send(PendingSyncCall call) async {
    await _pending.add(call);
    unawaited(_flushPending());
  }

  /// Chờ lượt gửi lại đang chạy (nếu có) kết thúc.
  @visibleForTesting
  Future<void> get idle => _flushing ?? Future<void>.value();

  Future<void> _flushPending() =>
      _flushing ??= _flushQueue().whenComplete(() => _flushing = null);

  /// Gửi lần lượt theo đúng thứ tự. Lỗi mạng thì dừng và giữ phần còn lại cho
  /// lần sau; máy chủ từ chối hẳn (tài khoản hết hạn, dữ liệu sai) thì bỏ lệnh
  /// đó vì gửi lại cũng không khác.
  Future<void> _flushQueue() async {
    if (!_remote.isSignedIn) return;
    final calls = await _pending.fetchAll();
    var handled = 0;
    for (final call in calls) {
      try {
        await _remote.rpc(call.function, call.params);
      } catch (error) {
        if (!_isRejected(error)) break;
      }
      handled++;
    }
    if (handled == 0) return;
    // Đọc lại vì trong lúc gửi có thể có lệnh mới được thêm vào cuối.
    final current = await _pending.fetchAll();
    await _pending.replaceAll(current.skip(handled).toList());
  }

  static bool _isRejected(Object error) {
    if (error is! PostgrestException) return false;
    final code = error.code ?? '';
    return code == '42501' || code.startsWith('22') || code.startsWith('23');
  }

  static DateTime _remoteUpdatedAt(Map<String, dynamic> row) =>
      DateTime.parse(row['client_updated_at'] as String).toLocal();

  static JournalEntry? _matchingEntry(
    List<JournalEntry> entries, {
    required String? syncId,
    required int? localEntryId,
    required DateTime occurredAt,
  }) {
    for (final entry in entries) {
      if (!entry.tags.contains('Session')) continue;
      final sameSyncId = syncId != null && entry.syncId == syncId;
      final sameLegacyEntry =
          entry.syncId == null &&
          entry.id == localEntryId &&
          entry.createdAt.difference(occurredAt).abs() <
              const Duration(minutes: 2);
      if (sameSyncId || sameLegacyEntry) return entry;
    }
    return null;
  }

  static JournalEntry _entryFromRemote(
    Map<String, dynamic> row, {
    int? localId,
  }) {
    final score = (row['mood_after'] as num?)?.toInt();
    final rawTags = row['tags'] as List<dynamic>? ?? const [];
    return JournalEntry(
      id: localId,
      syncId: row['client_entry_id'] as String,
      mood: score == null ? null : Mood.fromScore(score),
      note: row['note'] as String? ?? '',
      tags: rawTags.cast<String>(),
      createdAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
      updatedAt: _remoteUpdatedAt(row),
    );
  }

  static String _newUuid() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
