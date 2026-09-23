import 'package:embrace_ai/core/theme.dart';
import 'package:embrace_ai/models/journal_entry.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:embrace_ai/screens/home_screen.dart';
import 'package:embrace_ai/state/journal_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:embrace_ai/state/settings_store.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'support/fake_repository.dart';

/// Store đã nạp xong dữ liệu — màn hình sẽ không kẹt ở spinner.
Future<JournalStore> _loadedStore([List<JournalEntry> seed = const []]) async {
  final store = JournalStore(FakeRepository(seed));
  await store.load();
  return store;
}


/// Viewport trong test nhỏ hơn màn hình thật, và ListView chỉ dựng phần đang
/// nhìn thấy — nên widget dưới đáy phải cuộn tới mới tồn tại trong cây.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    // Chỉ định rõ scrollable ngoài cùng: ô nhập liệu cũng là một Scrollable.
    await tester.scrollUntilVisible(
      finder,
      120,
      maxScrolls: 30,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
}

Future<void> _tapAfterScroll(WidgetTester tester, Finder finder) async {
  await _scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Mở tab Journal — tab đầu tiên giờ là màn hình buổi thiền.
Future<void> _openJournal(WidgetTester tester) async {
  await tester.tap(find.text('Journal'));
  await tester.pumpAndSettle();
}

/// Dựng đúng cây widget như app thật, chỉ thay kho lưu trữ bằng bản giả.
Widget _app(JournalStore store) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: store),
      ChangeNotifierProvider(create: (_) => SettingsStore()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('en');
  });

  testWidgets('empty journal invites the first entry',
      (tester) async {
    final store = await _loadedStore();
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();
    await _openJournal(tester);

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Write the first line'), findsOneWidget);
  });

  testWidgets('writing an entry shows it in the list', (tester) async {
    final store = await _loadedStore();
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();
    await _openJournal(tester);

    await tester.tap(find.text('Write the first line'));
    await tester.pumpAndSettle();
    expect(find.text('How was today?'), findsOneWidget);

    await tester.tap(find.text(Mood.great.label));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'An easier day.');
    await tester.pumpAndSettle();

    await _tapAfterScroll(tester, find.text('Work'));
    await _tapAfterScroll(tester, find.text('Save'));

    // Đã quay về danh sách, dòng vừa ghi hiện lên dưới nhóm "Hôm nay".
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('An easier day.'), findsOneWidget);
    expect(store.entries, hasLength(1));
    expect(store.entries.first.mood, Mood.great);
    expect(store.entries.first.tags, ['Work']);
  });

  testWidgets('opening an old entry and changing its mood', (tester) async {
    final store = await _loadedStore([
      fakeEntry(id: 1, daysAgo: 0, mood: Mood.low, note: 'So tired.'),
    ]);
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();
    await _openJournal(tester);

    await tester.tap(find.text('So tired.'));
    await tester.pumpAndSettle();
    expect(find.text('So tired.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text(Mood.good.label));
    await tester.pumpAndSettle();
    await _tapAfterScroll(tester, find.text('Save changes'));

    expect(store.entries.single.mood, Mood.good);
  });

  testWidgets('deleting an entry returns to the empty list',
      (tester) async {
    final store = await _loadedStore([
      fakeEntry(id: 1, daysAgo: 0, note: 'Drop this.'),
    ]);
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();
    await _openJournal(tester);

    await tester.tap(find.text('Drop this.'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(store.entries, isEmpty);
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('insights tab builds with real data', (tester) async {
    final store = await _loadedStore([
      fakeEntry(id: 1, daysAgo: 0, mood: Mood.great, tags: ['Work']),
      fakeEntry(id: 2, daysAgo: 1, mood: Mood.neutral, tags: ['Work']),
      fakeEntry(id: 3, daysAgo: 2, mood: Mood.low),
    ]);
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Mood over 14 days'), findsOneWidget);
    expect(find.text('Where you usually sit'), findsOneWidget);
    // 3 dòng, trung bình (5 + 3 + 2) / 3 = 3.3
    expect(find.text('3.3'), findsOneWidget);
    await _scrollTo(tester, find.text('Mentioned most'));
    expect(find.text('Work  ·  2'), findsOneWidget);
  });

  testWidgets('insights tab with no data does not draw an empty chart',
      (tester) async {
    final store = await _loadedStore();
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing to show yet'), findsOneWidget);
  });
}
