import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal_entry.dart';
import '../models/mood.dart';
import 'journal_repository.dart';

class SessionSyncJournalRepository implements JournalRepository {
  SessionSyncJournalRepository({
    required JournalRepository local,
    JournalRepository? legacy,
    SupabaseClient? client,
  }) : _local = local,
       _legacy = legacy,
       _client = client ?? Supabase.instance.client;

  final JournalRepository _local;
  final JournalRepository? _legacy;
  final SupabaseClient _client;

  @override
  Future<List<JournalEntry>> fetchAll() async {
    final localEntries = await _local.fetchAll();
    final legacyEntries = await _legacy?.fetchAll() ?? const <JournalEntry>[];
    if (_client.auth.currentUser == null) return localEntries;

    try {
      final results = await Future.wait([
        _client
            .from('sessions')
            .select(
              'client_entry_id, local_entry_id, occurred_at, '
              'client_updated_at, mood_after',
            )
            .order('occurred_at', ascending: false),
        _client
            .from('participant_journal_entries')
            .select(
              'client_entry_id, occurred_at, client_updated_at, '
              'mood_after, note, tags',
            )
            .order('occurred_at', ascending: false),
      ]);
      final rows = results[0].cast<Map<String, dynamic>>();
      final privateRows = results[1].cast<Map<String, dynamic>>();
      final privateBySyncId = <String, Map<String, dynamic>>{
        for (final row in privateRows)
          if (row['client_entry_id'] case final String syncId) syncId: row,
      };
      final merged = <JournalEntry>[];
      final matchedLocalIds = <int>{};
      final remoteSyncIds = <String>{};

      for (final row in rows) {
        final syncId = row['client_entry_id'] as String?;
        if (syncId != null) remoteSyncIds.add(syncId);
        final privateRow = syncId == null ? null : privateBySyncId[syncId];
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
            note:
                'Session completed on another device. Private reflections '
                'remain on the device where they were written.',
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

  @override
  Future<void> delete(int id) => _local.delete(id);

  Future<void> _syncSession(JournalEntry entry) async {
    if (_client.auth.currentUser == null ||
        entry.id == null ||
        entry.syncId == null) {
      return;
    }
    try {
      await _client.rpc(
        'sync_session_journal',
        params: {
          'p_local_entry_id': entry.id,
          'p_client_entry_id': entry.syncId,
          'p_occurred_at': entry.createdAt.toUtc().toIso8601String(),
          'p_client_updated_at': entry.updatedAt.toUtc().toIso8601String(),
          'p_mood_after': entry.mood?.score,
          'p_note': entry.note,
          'p_tags': entry.tags,
        },
      );
    } catch (_) {
      // The on-device journal remains the source of truth if sync is offline.
    }
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
