import 'dart:convert';
import 'dart:io';

import 'package:embrace_ai/app.dart';
import 'package:embrace_ai/data/session_script.dart';
import 'package:embrace_ai/l10n/source_names.dart';
import 'package:embrace_ai/screens/home_screen.dart';
import 'package:embrace_ai/state/journal_store.dart';
import 'package:embrace_ai/state/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_repository.dart';

/// Chức năng chuyển ngôn ngữ của app người tham gia (tiếng Anh / tiếng Việt).
void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('vi');
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Map<String, dynamic> arb(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync())
          as Map<String, dynamic>;

  group('bản dịch', () {
    final en = arb('app_en.arb');
    final vi = arb('app_vi.arb');
    final keys = en.keys.where((key) => !key.startsWith('@')).toList();
    final placeholder = RegExp(r'\{(\w+)');

    test('mọi câu tiếng Anh đều có bản tiếng Việt, không rỗng', () {
      final missing = [
        for (final key in keys)
          if ((vi[key] as String?)?.trim().isEmpty ?? true) key,
      ];
      expect(missing, isEmpty, reason: 'thiếu bản tiếng Việt: $missing');
    });

    test('bản tiếng Việt dùng đúng các chỗ điền như bản tiếng Anh', () {
      for (final key in keys) {
        final meta = en['@$key'] as Map<String, dynamic>?;
        final declared =
            (meta?['placeholders'] as Map<String, dynamic>?)?.keys ??
            const <String>[];
        final vietnamese = vi[key] as String;
        for (final name in declared) {
          expect(vietnamese, contains('{$name'), reason: '$key thiếu {$name}');
        }
        final used = {
          for (final match in placeholder.allMatches(vietnamese)) match[1]!,
        };
        expect(used.difference(declared.toSet()), isEmpty, reason: key);
      }
    });

    test('bản tiếng Anh không lẫn chữ tiếng Việt', () {
      final viet = RegExp('[ăâđêôơưàáảãạèéẻẽẹìíỉĩịòóỏõọùúủũụ]');
      final mixed = [
        for (final key in keys)
          if (viet.hasMatch(en[key] as String)) key,
      ];
      expect(mixed, isEmpty);
    });

    test('mọi tài liệu nguồn của Ask EmbraceAI có tên tiếng Việt', () {
      // Đọc thẳng tài liệu gốc: mỗi mục `## ` là một tiêu đề đoạn trên kệ.
      final content = Directory('tools/ai-lab/content');
      final manifest =
          jsonDecode(File('${content.path}/manifest.json').readAsStringSync())
              as Map<String, dynamic>;
      final names = {
        for (final slug in manifest.keys)
          for (final line in File(
            '${content.path}/$slug.md',
          ).readAsLinesSync())
            if (line.startsWith('## ')) line.substring(3).trim(),
        for (final document in manifest.values)
          (document as Map<String, dynamic>)['title'],
      };
      final missing = names.difference(vietnameseSourceNames.keys.toSet());
      expect(missing, isEmpty, reason: 'thiếu tên tiếng Việt: $missing');
    });

    test('mọi câu phụ đề có bản tiếng Việt cùng mốc thời gian', () {
      for (final beat in SessionScript.beats) {
        expect(beat.titleFor('vi'), isNotEmpty);
        for (final caption in beat.captions) {
          expect(caption.textVi.trim(), isNotEmpty, reason: caption.text);
          expect(caption.textVi, isNot(caption.text));
          expect(caption.textFor('vi'), caption.textVi);
          expect(caption.textFor('en'), caption.text);
        }
      }
    });
  });

  group('lựa chọn ngôn ngữ', () {
    test('mặc định theo điện thoại và được nhớ lại', () async {
      final first = SettingsStore();
      await first.load();
      expect(first.language, AppLanguage.system);
      expect(first.language.locale, isNull);

      await first.setLanguage(AppLanguage.vietnamese);
      final restored = SettingsStore();
      await restored.load();
      expect(restored.language, AppLanguage.vietnamese);
      expect(restored.language.locale, const Locale('vi'));
    });
  });

  group('trong app', () {
    Future<SettingsStore> pumpApp(
      WidgetTester tester, {
      AppLanguage language = AppLanguage.system,
      double textScale = 1,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final settings = SettingsStore();
      await settings.setLanguage(language);
      await settings.setTextScale(textScale);
      final journal = JournalStore(FakeRepository());
      await journal.load();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: journal),
          ],
          child: EmbraceApp(
            home: HomeScreen(
              participantCode: 'EA1234ABCD',
              onSignOut: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return settings;
    }

    testWidgets('chưa chọn thì theo ngôn ngữ của điện thoại', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('vi', 'VN')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpApp(tester);

      expect(find.text('Buổi tập'), findsOneWidget);
      expect(find.text('Nhật ký'), findsOneWidget);
      expect(find.text('Một phút tĩnh lặng'), findsOneWidget);
    });

    testWidgets('điện thoại ngôn ngữ khác thì dùng tiếng Anh', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpApp(tester);

      expect(find.text('Session'), findsOneWidget);
      expect(find.text('A quiet moment'), findsOneWidget);
    });

    testWidgets('đổi ngôn ngữ từ nút trên thanh tiêu đề có hiệu lực ngay', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final settings = await pumpApp(tester);
      expect(find.text('Journal'), findsOneWidget);

      await tester.tap(find.byTooltip('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếng Việt'));
      await tester.pumpAndSettle();

      expect(settings.language, AppLanguage.vietnamese);
      expect(find.text('Nhật ký'), findsOneWidget);

      // Chọn lại tiếng Anh từ chính bảng chọn, giờ đang hiện tiếng Việt.
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(settings.language, AppLanguage.english);
      expect(find.text('Journal'), findsOneWidget);
    });

    testWidgets('tiếng Việt ở cỡ chữ 200% không tràn', (tester) async {
      await pumpApp(tester, language: AppLanguage.vietnamese, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Bắt đầu'), findsOneWidget);

      for (final tab in ['Nhật ký', 'Thống kê']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
    });
  });
}
