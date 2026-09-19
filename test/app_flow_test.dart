import 'package:embrace_ai/core/theme.dart';
import 'package:embrace_ai/models/journal_entry.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:embrace_ai/screens/home_screen.dart';
import 'package:embrace_ai/state/journal_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
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

/// Dựng đúng cây widget như app thật, chỉ thay SQLite bằng repository giả.
Widget _app(JournalStore store) {
  return ChangeNotifierProvider.value(
    value: store,
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
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
  setUpAll(() async => initializeDateFormatting('vi'));

  testWidgets('nhật ký trống mời người dùng ghi dòng đầu tiên',
      (tester) async {
    final store = await _loadedStore();
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có dòng nào'), findsOneWidget);
    expect(find.text('Ghi dòng đầu tiên'), findsOneWidget);
  });

  testWidgets('ghi một dòng mới rồi thấy nó trong danh sách', (tester) async {
    final store = await _loadedStore();
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ghi dòng đầu tiên'));
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay thế nào?'), findsOneWidget);

    await tester.tap(find.text(Mood.great.label));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Một ngày dễ thở.');
    await tester.pumpAndSettle();

    await _tapAfterScroll(tester, find.text('Công việc'));
    await _tapAfterScroll(tester, find.text('Lưu lại'));

    // Đã quay về danh sách, dòng vừa ghi hiện lên dưới nhóm "Hôm nay".
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Một ngày dễ thở.'), findsOneWidget);
    expect(store.entries, hasLength(1));
    expect(store.entries.first.mood, Mood.great);
    expect(store.entries.first.tags, ['Công việc']);
  });

  testWidgets('mở một dòng cũ rồi sửa tâm trạng', (tester) async {
    final store = await _loadedStore([
      fakeEntry(id: 1, daysAgo: 0, mood: Mood.low, note: 'Mệt quá.'),
    ]);
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mệt quá.'));
    await tester.pumpAndSettle();
    expect(find.text('Mệt quá.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text(Mood.good.label));
    await tester.pumpAndSettle();
    await _tapAfterScroll(tester, find.text('Lưu thay đổi'));

    expect(store.entries.single.mood, Mood.good);
  });

  testWidgets('xoá một dòng đưa người dùng về danh sách trống',
      (tester) async {
    final store = await _loadedStore([
      fakeEntry(id: 1, daysAgo: 0, note: 'Bỏ đi.'),
    ]);
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bỏ đi.'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();

    expect(store.entries, isEmpty);
    expect(find.text('Chưa có dòng nào'), findsOneWidget);
  });

  testWidgets('tab Thống kê dựng được với dữ liệu thật', (tester) async {
    final store = await _loadedStore([
      fakeEntry(id: 1, daysAgo: 0, mood: Mood.great, tags: ['Công việc']),
      fakeEntry(id: 2, daysAgo: 1, mood: Mood.neutral, tags: ['Công việc']),
      fakeEntry(id: 3, daysAgo: 2, mood: Mood.low),
    ]);
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thống kê'));
    await tester.pumpAndSettle();

    expect(find.text('Chuỗi liên tiếp'), findsOneWidget);
    expect(find.text('Tâm trạng 14 ngày qua'), findsOneWidget);
    expect(find.text('Bạn thường ở mức nào'), findsOneWidget);
    // 3 dòng, trung bình (5 + 3 + 2) / 3 = 3.3
    expect(find.text('3.3'), findsOneWidget);
    await _scrollTo(tester, find.text('Nhắc tới nhiều nhất'));
    expect(find.text('Công việc  ·  2'), findsOneWidget);
  });

  testWidgets('tab Thống kê khi chưa có dữ liệu không dựng biểu đồ rỗng',
      (tester) async {
    final store = await _loadedStore();
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thống kê'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có gì để xem'), findsOneWidget);
  });
}
