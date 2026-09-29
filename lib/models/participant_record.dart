import 'consent.dart';
import 'study_assessment.dart';

export 'consent.dart';

enum ParticipantStatus { invited, active, suspended, completed }

class ParticipantRecord {
  const ParticipantRecord({
    required this.code,
    required this.studyId,
    required this.group,
    required this.status,
    required this.consentStatus,
    required this.sessionCount,
    required this.createdAt,
    this.demographicsStatus = FormCompletionStatus.notStarted,
    this.finalAssessmentStatus = FinalAssessmentStatus.notDue,
    this.lastActivityAt,
    this.activatedAt,
    this.expiresAt,
    this.finalAssessmentOpenedAt,
    this.consentVersion,
    this.consentRecordedAt,
    this.consentSource,
  });

  final String code;
  final String studyId;
  final String group;
  final ParticipantStatus status;
  final ConsentStatus consentStatus;
  final int sessionCount;
  final DateTime createdAt;
  final FormCompletionStatus demographicsStatus;
  final FinalAssessmentStatus finalAssessmentStatus;
  final DateTime? lastActivityAt;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final DateTime? finalAssessmentOpenedAt;
  final String? consentVersion;
  final DateTime? consentRecordedAt;
  final String? consentSource;

  bool get isActive => status == ParticipantStatus.active;

  factory ParticipantRecord.fromSupabase(Map<String, dynamic> data) {
    return ParticipantRecord(
      code: data['participant_code'] as String,
      studyId: data['study_id'] as String? ?? 'CARDIAC-MIND-01',
      group: data['group_name'] as String? ?? 'Unassigned',
      status: ParticipantStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => ParticipantStatus.invited,
      ),
      consentStatus: ConsentStatus.values.firstWhere(
        (value) => value.name == data['consent_status'],
        orElse: () => ConsentStatus.pending,
      ),
      sessionCount: (data['session_count'] as num?)?.toInt() ?? 0,
      createdAt: _date(data['created_at']) ?? DateTime.now(),
      demographicsStatus: switch (data['demographics_status']) {
        'draft' => FormCompletionStatus.draft,
        'submitted' => FormCompletionStatus.submitted,
        _ => FormCompletionStatus.notStarted,
      },
      finalAssessmentStatus: switch (data['final_assessment_status']) {
        'due' => FinalAssessmentStatus.due,
        'in_progress' => FinalAssessmentStatus.inProgress,
        'submitted' => FinalAssessmentStatus.submitted,
        _ => FinalAssessmentStatus.notDue,
      },
      lastActivityAt: _date(data['last_activity_at']),
      activatedAt: _date(data['activated_at']),
      expiresAt: _date(data['expires_at']),
      finalAssessmentOpenedAt: _date(data['final_assessment_opened_at']),
      consentVersion: data['consent_version'] as String?,
      consentRecordedAt: _date(data['consent_recorded_at']),
      consentSource: data['consent_source'] as String?,
    );
  }

  static DateTime? _date(Object? value) => switch (value) {
    DateTime date => date,
    String text => DateTime.tryParse(text)?.toLocal(),
    _ => null,
  };
}

class ParticipantSessionRecord {
  const ParticipantSessionRecord({
    required this.occurredAt,
    required this.moodAfter,
  });

  final DateTime occurredAt;
  final int? moodAfter;

  factory ParticipantSessionRecord.fromSupabase(Map<String, dynamic> data) =>
      ParticipantSessionRecord(
        occurredAt: DateTime.parse(data['occurred_at'] as String).toLocal(),
        moodAfter: (data['mood_after'] as num?)?.toInt(),
      );
}

class ParticipantAccessCard {
  const ParticipantAccessCard({
    required this.code,
    required this.loginUrl,
    required this.expiresAt,
    this.accessKey,
  });

  final String code;
  final String loginUrl;
  final String? accessKey;
  final DateTime expiresAt;
}
