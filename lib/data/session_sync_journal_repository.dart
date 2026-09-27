import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal_entry.dart';
import 'journal_repository.dart';

class SessionSyncJournalRepository implements JournalRepository {
  SessionSyncJournalRepository({
    required JournalRepository local,
    SupabaseClient? client,
  }) : _local = local,
       _client = client ?? Supabase.instance.client;

  final JournalRepository _local;
  final SupabaseClient _client;

  @override
  Future<List<JournalEntry>> fetchAll() => _local.fetchAll();

  @override
  Future<JournalEntry> insert(JournalEntry entry) async {
    final saved = await _local.insert(entry);
    if (saved.tags.contains('Session')) await _syncSession(saved);
    return saved;
  }

  @override
  Future<void> update(JournalEntry entry) async {
    await _local.update(entry);
    if (entry.tags.contains('Session')) await _syncSession(entry);
  }

  @override
  Future<void> delete(int id) => _local.delete(id);

  Future<void> _syncSession(JournalEntry entry) async {
    if (_client.auth.currentUser == null || entry.id == null) return;
    try {
      await _client.rpc(
        'record_session',
        params: {
          'p_local_entry_id': entry.id,
          'p_occurred_at': entry.createdAt.toUtc().toIso8601String(),
          'p_client_updated_at': entry.updatedAt.toUtc().toIso8601String(),
          'p_mood_after': entry.mood?.score,
          'p_reflection_provided': entry.note.trim().isNotEmpty,
        },
      );
    } catch (_) {
      // The on-device journal remains the source of truth if sync is offline.
    }
  }
}
