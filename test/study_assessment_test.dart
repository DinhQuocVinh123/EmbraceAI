import 'package:embrace_ai/models/study_assessment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('complete GAD responses calculate GAD-2 and GAD-7 totals', () {
    final answers = ProgramAssessmentAnswers(
      gadResponses: [1, 2, 3, 0, 1, 2, 3],
    );

    expect(answers.gad2Score, 3);
    expect(answers.gad7Score, 12);
  });

  test('missing GAD items do not silently become zero', () {
    final answers = ProgramAssessmentAnswers(
      gadResponses: [1, null, 3, 0, 1, 2, 3],
    );

    expect(answers.gad2Score, isNull);
    expect(answers.gad7Score, isNull);
  });

  test('assessment JSON preserves item-level responses and blanks', () {
    final answers = ProgramAssessmentAnswers(
      gadResponses: [0, 1, 2, 3, null, null, null],
      emotionalWellbeing: 4,
      premResponses: [5, 4, 3, 2, 1, null, null, null],
      openResponses: [' Helpful ', '', '', 'Would use again'],
    );

    final json = answers.toJson();
    expect(json['gad_1'], 0);
    expect(json['gad_5'], isNull);
    expect(json['emotional_wellbeing'], 4);
    expect(json['prem_5'], 1);
    expect(json['open_1'], 'Helpful');
    expect(json['open_2'], isNull);
  });

  test('progress identifies baseline and final assessment gates', () {
    final progress = StudyProgress.fromSupabase({
      'demographics_status': 'submitted',
      'final_assessment_status': 'due',
    });

    expect(progress.needsDemographics, isFalse);
    expect(progress.needsFinalAssessment, isTrue);
  });
}
