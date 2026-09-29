import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/participant_record.dart';
import '../models/study_assessment.dart';

class StaffPortalService {
  StaffPortalService({
    SupabaseClient? client,
    Duration pollInterval = const Duration(seconds: 10),
  }) : _client = client ?? Supabase.instance.client,
       _pollInterval = pollInterval;

  final SupabaseClient _client;
  final Duration _pollInterval;

  Stream<List<ParticipantRecord>> watchParticipants() async* {
    while (true) {
      yield await loadParticipants();
      await Future<void>.delayed(_pollInterval);
    }
  }

  Future<List<ParticipantRecord>> loadParticipants() async {
    final rows = await _client
        .from('participants')
        .select()
        .order('created_at', ascending: false);
    return rows.map(ParticipantRecord.fromSupabase).toList(growable: false);
  }

  Stream<List<ParticipantSessionRecord>> watchSessions(String code) async* {
    while (true) {
      yield await loadSessions(code);
      await Future<void>.delayed(_pollInterval);
    }
  }

  Future<List<ParticipantSessionRecord>> loadSessions(String code) async {
    final rows = await _client
        .from('sessions')
        .select()
        .eq('participant_code', code)
        .order('occurred_at', ascending: false)
        .limit(30);
    return rows
        .map(ParticipantSessionRecord.fromSupabase)
        .toList(growable: false);
  }

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
      accessKey: data['accessKey'] as String?,
      loginUrl: data['loginUrl'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String).toLocal(),
      reissued: true,
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

  Future<void> openFinalAssessment(String code) async {
    await _client.rpc('open_final_assessment', params: {'target_code': code});
  }

  Future<StudyResponseSummary> loadStudyResponses(String code) async {
    final responses = await Future.wait([
      _client
          .from('participant_demographics')
          .select()
          .eq('participant_code', code)
          .maybeSingle(),
      _client
          .from('program_assessments')
          .select()
          .eq('participant_code', code)
          .eq('timepoint', 'final')
          .maybeSingle(),
    ]);
    final demographics = responses[0];
    final assessment = responses[1];
    return StudyResponseSummary(
      demographics: demographics == null
          ? null
          : DemographicAnswers.fromSupabase(demographics),
      finalAssessment: assessment == null
          ? null
          : ProgramAssessmentAnswers.fromSupabase(assessment),
      finalSubmittedAt: assessment == null
          ? null
          : DateTime.tryParse(
              assessment['submitted_at'] as String? ?? '',
            )?.toLocal(),
    );
  }
}
