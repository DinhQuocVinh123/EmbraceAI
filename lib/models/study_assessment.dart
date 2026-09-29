import 'consent.dart';

enum FormCompletionStatus { notStarted, draft, submitted }

enum FinalAssessmentStatus { notDue, due, inProgress, submitted }

const studyFormVersion = '2026-04-16-v1';

class StudyProgress {
  const StudyProgress({
    required this.consentStatus,
    required this.demographicsStatus,
    required this.finalAssessmentStatus,
  });

  final ConsentStatus consentStatus;
  final FormCompletionStatus demographicsStatus;
  final FinalAssessmentStatus finalAssessmentStatus;

  bool get needsConsent => consentStatus == ConsentStatus.pending;
  bool get consentWithdrawn => consentStatus == ConsentStatus.withdrawn;
  bool get needsDemographics =>
      demographicsStatus != FormCompletionStatus.submitted;
  bool get needsFinalAssessment =>
      finalAssessmentStatus == FinalAssessmentStatus.due ||
      finalAssessmentStatus == FinalAssessmentStatus.inProgress;

  factory StudyProgress.fromSupabase(Map<String, dynamic> data) {
    return StudyProgress(
      consentStatus: ConsentStatus.values.firstWhere(
        (value) => value.name == data['consent_status'],
        orElse: () => ConsentStatus.pending,
      ),
      demographicsStatus: _formStatus(data['demographics_status']),
      finalAssessmentStatus: _finalStatus(data['final_assessment_status']),
    );
  }
}

class DemographicAnswers {
  const DemographicAnswers({
    this.ageYears,
    this.gender,
    this.ethnicBackground,
    this.ethnicOther,
    this.countryOfBirth,
    this.relationshipStatus,
    this.cardiovascularDiagnosis,
    this.comorbidities,
  });

  final int? ageYears;
  final String? gender;
  final String? ethnicBackground;
  final String? ethnicOther;
  final String? countryOfBirth;
  final String? relationshipStatus;
  final String? cardiovascularDiagnosis;
  final String? comorbidities;

  Map<String, dynamic> toJson() => {
    'age_years': ageYears,
    'gender': gender,
    'ethnic_background': ethnicBackground,
    'ethnic_other': _clean(ethnicOther),
    'country_of_birth': _clean(countryOfBirth),
    'relationship_status': relationshipStatus,
    'cardiovascular_diagnosis': _clean(cardiovascularDiagnosis),
    'comorbidities': _clean(comorbidities),
  };

  factory DemographicAnswers.fromSupabase(Map<String, dynamic> data) {
    return DemographicAnswers(
      ageYears: (data['age_years'] as num?)?.toInt(),
      gender: data['gender'] as String?,
      ethnicBackground: data['ethnic_background'] as String?,
      ethnicOther: data['ethnic_other'] as String?,
      countryOfBirth: data['country_of_birth'] as String?,
      relationshipStatus: data['relationship_status'] as String?,
      cardiovascularDiagnosis: data['cardiovascular_diagnosis'] as String?,
      comorbidities: data['comorbidities'] as String?,
    );
  }
}

class ProgramAssessmentAnswers {
  ProgramAssessmentAnswers({
    List<int?>? gadResponses,
    this.emotionalWellbeing,
    List<int?>? premResponses,
    List<String>? openResponses,
  }) : gadResponses = _fixed<int?>(gadResponses, 7),
       premResponses = _fixed<int?>(premResponses, 8),
       openResponses = _fixed<String>(openResponses, 4, fill: '');

  final List<int?> gadResponses;
  int? emotionalWellbeing;
  final List<int?> premResponses;
  final List<String> openResponses;

  int? get gad2Score => _score(gadResponses.take(2));
  int? get gad7Score => _score(gadResponses);

  Map<String, dynamic> toJson() => {
    for (var index = 0; index < gadResponses.length; index++)
      'gad_${index + 1}': gadResponses[index],
    'emotional_wellbeing': emotionalWellbeing,
    for (var index = 0; index < premResponses.length; index++)
      'prem_${index + 1}': premResponses[index],
    for (var index = 0; index < openResponses.length; index++)
      'open_${index + 1}': _clean(openResponses[index]),
  };

  factory ProgramAssessmentAnswers.fromSupabase(Map<String, dynamic> data) {
    return ProgramAssessmentAnswers(
      gadResponses: [
        for (var index = 1; index <= 7; index++)
          (data['gad_$index'] as num?)?.toInt(),
      ],
      emotionalWellbeing: (data['emotional_wellbeing'] as num?)?.toInt(),
      premResponses: [
        for (var index = 1; index <= 8; index++)
          (data['prem_$index'] as num?)?.toInt(),
      ],
      openResponses: [
        for (var index = 1; index <= 4; index++)
          data['open_$index'] as String? ?? '',
      ],
    );
  }

  static int? _score(Iterable<int?> values) {
    final items = values.toList(growable: false);
    if (items.any((value) => value == null)) return null;
    return items.whereType<int>().fold<int>(0, (total, value) => total + value);
  }
}

class StudyResponseSummary {
  const StudyResponseSummary({
    this.demographics,
    this.finalAssessment,
    this.finalSubmittedAt,
  });

  final DemographicAnswers? demographics;
  final ProgramAssessmentAnswers? finalAssessment;
  final DateTime? finalSubmittedAt;
}

FormCompletionStatus _formStatus(Object? value) => switch (value) {
  'draft' => FormCompletionStatus.draft,
  'submitted' => FormCompletionStatus.submitted,
  _ => FormCompletionStatus.notStarted,
};

FinalAssessmentStatus _finalStatus(Object? value) => switch (value) {
  'due' => FinalAssessmentStatus.due,
  'in_progress' => FinalAssessmentStatus.inProgress,
  'submitted' => FinalAssessmentStatus.submitted,
  _ => FinalAssessmentStatus.notDue,
};

String? _clean(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

List<T> _fixed<T>(List<T>? values, int length, {T? fill}) {
  final output = List<T>.from(values ?? const []);
  while (output.length < length) {
    output.add(fill as T);
  }
  return output.take(length).toList(growable: false);
}
