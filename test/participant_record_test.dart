import 'package:embrace_ai/models/participant_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('participant record maps consent status from Supabase columns', () {
    final record = ParticipantRecord.fromSupabase({
      'participant_code': 'EA23AB89XY',
      'study_id': 'CARDIAC-MIND-01',
      'group_name': 'Intervention',
      'status': 'active',
      'consent_status': 'accepted',
      'session_count': 2,
      'created_at': '2026-09-27T00:00:00Z',
    });

    expect(record.status, ParticipantStatus.active);
    expect(record.consentStatus, ConsentStatus.accepted);
    expect(record.sessionCount, 2);
  });
}
