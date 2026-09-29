import 'package:embrace_ai/data/prefs_journal_repository.dart';
import 'package:embrace_ai/models/journal_entry.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('journal entries are isolated by account namespace', () async {
    final participantA = PrefsJournalRepository(namespace: 'user-a');
    final participantB = PrefsJournalRepository(namespace: 'user-b');

    await participantA.insert(
      JournalEntry.draft(mood: Mood.great).copyWith(note: 'Private entry A'),
    );

    expect(await participantA.fetchAll(), hasLength(1));
    expect(await participantB.fetchAll(), isEmpty);

    await participantB.insert(
      JournalEntry.draft(mood: Mood.low).copyWith(note: 'Private entry B'),
    );

    expect((await participantA.fetchAll()).single.note, 'Private entry A');
    expect((await participantB.fetchAll()).single.note, 'Private entry B');
  });

  test(
    'legacy unscoped entries are not assigned to a signed-in account',
    () async {
      final legacy = PrefsJournalRepository();
      await legacy.insert(JournalEntry.draft(mood: Mood.neutral));

      final participant = PrefsJournalRepository(namespace: 'signed-in-user');

      expect(await legacy.fetchAll(), hasLength(1));
      expect(await participant.fetchAll(), isEmpty);
    },
  );
}
