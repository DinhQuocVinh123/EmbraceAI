import 'package:embrace_ai/data/pending_sync_queue.dart';
import 'package:embrace_ai/data/session_sync_journal_repository.dart';
import 'package:embrace_ai/models/journal_entry.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/fake_repository.dart';

/// Máy chủ giả, làm đúng như các hàm RPC trong migration.
class FakeServer implements SessionJournalRemote {
  final sessions = <String, Map<String, dynamic>>{};
  final privateEntries = <String, Map<String, dynamic>>{};

  /// Tắt cả đọc lẫn ghi, giống máy mất mạng.
  bool online = true;

  /// Chỉ tắt việc gửi lệnh: đọc được nhưng gửi lỗi, giống mạng chập chờn.
  bool acceptsCalls = true;

  /// Lỗi máy chủ trả về cho mọi lệnh, ví dụ tài khoản đã hết hạn.
  PostgrestException? rejection;

  void _reach() {
    if (!online) throw Exception('offline');
  }

  @override
  bool get isSignedIn => true;

  @override
  Future<List<Map<String, dynamic>>> fetchSessions() async {
    _reach();
    return [
      for (final row in sessions.values) {...row},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPrivateEntries() async {
    _reach();
    return [
      for (final row in privateEntries.values) {...row},
    ];
  }

  @override
  Future<void> rpc(String function, Map<String, Object?> params) async {
    _reach();
    if (!acceptsCalls) throw Exception('connection reset');
    if (rejection case final error?) throw error;
    final id = params['p_client_entry_id'] as String;
    final existing = sessions[id];
    final session = <String, dynamic>{
      'client_entry_id': id,
      'local_entry_id': params['p_local_entry_id'],
      'occurred_at': params['p_occurred_at'],
      'client_updated_at': params['p_client_updated_at'],
      'mood_after': params['p_mood_after'],
      'journal_deleted_at': existing?['journal_deleted_at'],
    };
    switch (function) {
      case 'record_session':
        sessions[id] = session;
      case 'sync_session_journal':
        if (existing?['journal_deleted_at'] != null) return;
        sessions[id] = session;
        privateEntries[id] = {
          'client_entry_id': id,
          'occurred_at': params['p_occurred_at'],
          'client_updated_at': params['p_client_updated_at'],
          'mood_after': params['p_mood_after'],
          'note': params['p_note'],
          'tags': params['p_tags'],
        };
      case 'delete_session_journal':
        sessions[id] = {
          ...existing ?? session,
          'local_entry_id': 0,
          'journal_deleted_at':
              existing?['journal_deleted_at'] ?? '2026-10-06T00:00:00Z',
        };
        privateEntries.remove(id);
      default:
        throw UnimplementedError(function);
    }
  }
}

/// Một máy của người tham gia: kho trên máy, hàng đợi và kho đồng bộ.
class Device {
  Device(this.server, this.name);

  final FakeServer server;
  final String name;
  final local = FakeRepository();

  PendingSyncQueue get queue => PendingSyncQueue(namespace: name);

  /// Tạo mới mỗi lần gọi, như mở lại app.
  SessionSyncJournalRepository open() => SessionSyncJournalRepository(
    local: local,
    pending: queue,
    remote: server,
  );
}

JournalEntry sessionNote(String note) {
  final at = DateTime(2026, 10, 5, 9);
  return JournalEntry(
    mood: Mood.low,
    note: note,
    tags: const ['Session'],
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('deleting a session journal entry', () {
    test('removes the note from the server but keeps the session', () async {
      final server = FakeServer();
      final phone = Device(server, 'phone').open();

      final saved = await phone.insert(sessionNote('Worried about results'));
      expect(server.privateEntries, hasLength(1));

      await phone.delete(saved.id!);
      await phone.idle;

      expect(server.privateEntries, isEmpty);
      expect(server.sessions, hasLength(1));
      expect(server.sessions.values.single['journal_deleted_at'], isNotNull);
      expect(await phone.fetchAll(), isEmpty);
    });

    test('is applied on other devices, even after they edit it', () async {
      final server = FakeServer();
      final phone = Device(server, 'phone').open();
      final laptopDevice = Device(server, 'laptop');
      final laptop = laptopDevice.open();

      final saved = await phone.insert(sessionNote('Worried about results'));
      final laptopCopy = (await laptop.fetchAll()).single;
      expect(laptopCopy.note, 'Worried about results');

      await phone.delete(saved.id!);
      await phone.idle;

      // Laptop chưa biết tin và sửa bản của mình: máy chủ không tạo lại.
      await laptop.update(laptopCopy.copyWith(note: 'Edited on laptop'));
      expect(server.privateEntries, isEmpty);

      expect(await laptop.fetchAll(), isEmpty);
      expect(await laptopDevice.local.fetchAll(), isEmpty);
    });

    test('made offline is sent later and never comes back', () async {
      final server = FakeServer();
      final phoneDevice = Device(server, 'phone');
      final phone = phoneDevice.open();

      final saved = await phone.insert(sessionNote('Private thought'));
      server.online = false;
      await phone.delete(saved.id!);
      await phone.idle;

      expect(server.privateEntries, hasLength(1));
      expect(await phoneDevice.queue.fetchAll(), hasLength(1));

      // Mạng chập chờn: đọc được nhưng chưa gửi được lệnh xoá.
      server
        ..online = true
        ..acceptsCalls = false;
      expect(await phoneDevice.open().fetchAll(), isEmpty);

      server.acceptsCalls = true;
      expect(await phoneDevice.open().fetchAll(), isEmpty);
      expect(server.privateEntries, isEmpty);
      expect(await phoneDevice.queue.fetchAll(), isEmpty);
    });
  });

  group('sessions skipped from the journal', () {
    test('recorded offline are sent when the app opens again', () async {
      final server = FakeServer()..online = false;
      final phoneDevice = Device(server, 'phone');
      final phone = phoneDevice.open();

      await phone.recordUnsavedSession(
        occurredAt: DateTime(2026, 10, 6, 9),
        moodAfter: Mood.good,
        reflectionProvided: false,
      );
      await phone.idle;
      expect(server.sessions, isEmpty);
      expect(await phoneDevice.queue.fetchAll(), hasLength(1));

      server.online = true;
      final reopened = phoneDevice.open();
      expect(await reopened.fetchAll(), isEmpty);

      final row = server.sessions.values.single;
      expect(row['local_entry_id'], 0);
      expect(row['mood_after'], Mood.good.score);
      expect(await phoneDevice.queue.fetchAll(), isEmpty);
    });

    test('rejected by the server are not retried', () async {
      final server = FakeServer()
        ..rejection = const PostgrestException(
          message: 'Active participant account required',
          code: '42501',
        );
      final phoneDevice = Device(server, 'phone');
      final phone = phoneDevice.open();

      await phone.recordUnsavedSession(
        occurredAt: DateTime(2026, 10, 6, 9),
        reflectionProvided: false,
      );
      await phone.idle;

      expect(server.sessions, isEmpty);
      expect(await phoneDevice.queue.fetchAll(), isEmpty);
    });
  });

  test('pending calls are kept per account', () async {
    await PendingSyncQueue(
      namespace: 'user-a',
    ).add(const PendingSyncCall('record_session', {'p_client_entry_id': 'a'}));

    expect(
      await PendingSyncQueue(namespace: 'user-a').fetchAll(),
      hasLength(1),
    );
    expect(await PendingSyncQueue(namespace: 'user-b').fetchAll(), isEmpty);
  });
}
