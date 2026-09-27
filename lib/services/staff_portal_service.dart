import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/participant_record.dart';

class StaffPortalService {
  StaffPortalService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Stream<List<ParticipantRecord>> watchParticipants() => _client
      .from('participants')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map(
        (rows) =>
            rows.map(ParticipantRecord.fromSupabase).toList(growable: false),
      );

  Stream<List<ParticipantSessionRecord>> watchSessions(String code) => _client
      .from('sessions')
      .stream(primaryKey: ['id'])
      .eq('participant_code', code)
      .order('occurred_at', ascending: false)
      .limit(30)
      .map(
        (rows) => rows
            .map(ParticipantSessionRecord.fromSupabase)
            .toList(growable: false),
      );

  Future<ParticipantAccessCard> createParticipant({
    required String studyId,
    required String group,
    int validForDays = 90,
  }) async {
    final response = await _client.functions.invoke(
      'create-participant',
      body: {
        'studyId': studyId.trim(),
        'group': group.trim().isEmpty ? 'Unassigned' : group.trim(),
        'validForDays': validForDays,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return ParticipantAccessCard(
      code: data['participantCode'] as String,
      accessKey: data['accessKey'] as String?,
      loginUrl: data['loginUrl'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String).toLocal(),
    );
  }

  Future<ParticipantAccessCard> reissueParticipantAccess(String code) async {
    final response = await _client.functions.invoke(
      'reissue-participant-access',
      body: {'participantCode': code},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return ParticipantAccessCard(
      code: data['participantCode'] as String,
      loginUrl: data['loginUrl'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String).toLocal(),
    );
  }

  Future<void> updateStatus(String code, ParticipantStatus status) async {
    await _client.rpc(
      'set_participant_status',
      params: {'target_code': code, 'new_status': status.name},
    );
  }

  Future<void> updateConsent(String code, ConsentStatus status) async {
    await _client.rpc(
      'set_consent_status',
      params: {'target_code': code, 'new_status': status.name},
    );
  }
}
