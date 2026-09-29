import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consent.dart';
import '../models/study_assessment.dart';

class StudyAssessmentService {
  StudyAssessmentService({
    SupabaseClient? client,
    Duration pollInterval = const Duration(seconds: 15),
  }) : _client = client ?? Supabase.instance.client,
       _pollInterval = pollInterval;

  final SupabaseClient _client;
  final Duration _pollInterval;

  Stream<StudyProgress> watchProgress(String participantCode) async* {
    while (true) {
      yield await loadProgress(participantCode);
      await Future<void>.delayed(_pollInterval);
    }
  }

  Future<StudyProgress> loadProgress(String participantCode) async {
    final row = await _client
        .from('participants')
        .select(
          'consent_status, demographics_status, final_assessment_status, '
          'final_assessment_opened_at',
        )
        .eq('participant_code', participantCode)
        .maybeSingle();
    if (row == null) {
      return const StudyProgress(
        consentStatus: ConsentStatus.pending,
        demographicsStatus: FormCompletionStatus.notStarted,
        finalAssessmentStatus: FinalAssessmentStatus.notDue,
      );
    }
    return StudyProgress.fromSupabase(row);
  }

  Future<void> acceptConsent() async {
    await _client.rpc(
      'record_participant_consent',
      params: {'p_consent_version': studyConsentVersion},
    );
  }

  Future<DemographicAnswers?> loadDemographics() async {
    final data = await _client
        .from('participant_demographics')
        .select()
        .maybeSingle();
    return data == null ? null : DemographicAnswers.fromSupabase(data);
  }

  Future<void> saveDemographics(
    DemographicAnswers answers, {
    required bool submit,
  }) async {
    await _client.rpc(
      'save_participant_demographics',
      params: {
        'p_form_version': studyFormVersion,
        'p_answers': answers.toJson(),
        'p_submit': submit,
      },
    );
  }

  Future<ProgramAssessmentAnswers?> loadAssessment(String timepoint) async {
    final data = await _client
        .from('program_assessments')
        .select()
        .eq('timepoint', timepoint)
        .maybeSingle();
    return data == null ? null : ProgramAssessmentAnswers.fromSupabase(data);
  }

  Future<void> saveAssessment(
    ProgramAssessmentAnswers answers, {
    String timepoint = 'final',
    required bool submit,
  }) async {
    await _client.rpc(
      'save_program_assessment',
      params: {
        'p_timepoint': timepoint,
        'p_form_version': studyFormVersion,
        'p_answers': answers.toJson(),
        'p_submit': submit,
      },
    );
  }
}
