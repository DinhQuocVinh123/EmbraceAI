import 'package:embrace_ai/core/theme.dart';
import 'package:embrace_ai/data/check_in_paths.dart';
import 'package:embrace_ai/l10n/l10n.dart';
import 'package:embrace_ai/l10n/labels.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:embrace_ai/models/session_answers.dart';
import 'package:embrace_ai/widgets/session_prompts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mỗi cảm xúc ở bước check-in có câu hỏi, thang và gợi ý riêng (biên bản họp,
/// mục 1: trước đây mọi cảm xúc đều bị hỏi "How stressed do you feel?").
void main() {
  Future<void> pump(WidgetTester tester, Widget prompt) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(child: prompt),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Chọn cảm xúc, kéo thang tới [level], bấm Continue.
  Future<void> checkIn(
    WidgetTester tester,
    CheckInFeeling feeling,
    int level,
  ) async {
    await tester.tap(find.text(feeling.label(english)));
    await tester.pumpAndSettle();
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(level.toDouble());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  for (final feeling in CheckInFeeling.values) {
    testWidgets('${feeling.name}: asks about that feeling, not about stress', (
      tester,
    ) async {
      await pump(tester, CheckInPrompt(onDone: (a, b, c, d) {}, onSkip: () {}));
      await tester.tap(find.text(feeling.label(english)));
      await tester.pumpAndSettle();

      expect(find.text(feeling.scaleTitle(english)), findsOneWidget);
      expect(find.text(feeling.scaleLow(english)), findsOneWidget);
      expect(find.text(feeling.scaleHigh(english)), findsOneWidget);
      if (feeling != CheckInFeeling.stressed) {
        expect(find.textContaining('stress'), findsNothing);
      }
    });
  }

  testWidgets('every feeling has its own question in both languages', (
    tester,
  ) async {
    for (final l in [english, lookupAppLocalizations(const Locale('vi'))]) {
      final titles = {for (final f in CheckInFeeling.values) f.scaleTitle(l)};
      final after = {for (final f in CheckInFeeling.values) f.afterTitle(l)};
      expect(titles, hasLength(CheckInFeeling.values.length));
      expect(after, hasLength(CheckInFeeling.values.length));
    }
  });

  testWidgets('very tired suggests the gentle breathing practice first', (
    tester,
  ) async {
    PracticeChoice? chosen;
    int? level;
    await pump(
      tester,
      CheckInPrompt(
        onDone: (feeling, value, practice, length) {
          level = value;
          chosen = practice;
        },
        onSkip: () {},
      ),
    );
    await checkIn(tester, CheckInFeeling.tired, 8);

    expect(find.text("Let's keep this gentle"), findsOneWidget);
    expect(find.textContaining('Your energy is low'), findsOneWidget);
    final buttons = tester.widgetList<ChoiceButton>(find.byType(ChoiceButton));
    expect(buttons.first.label, 'Follow the breath');
    expect(buttons.first.description, startsWith('Suggested · '));
    expect(buttons.last.description, isNot(startsWith('Suggested')));

    await tester.tap(find.text('Follow the breath'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Short practice'));
    expect(chosen, PracticeChoice.breathing);
    expect(level, 8);
  });

  for (final feeling in [
    CheckInFeeling.stressed,
    CheckInFeeling.upset,
    CheckInFeeling.distracted,
  ]) {
    testWidgets('strong ${feeling.name} suggests grounding first', (
      tester,
    ) async {
      await pump(tester, CheckInPrompt(onDone: (a, b, c, d) {}, onSkip: () {}));
      await checkIn(tester, feeling, 9);

      expect(find.text(feeling.strongBody(english)!), findsOneWidget);
      final first = tester
          .widgetList<ChoiceButton>(find.byType(ChoiceButton))
          .first;
      expect(first.label, 'Grounding');
      expect(first.description, startsWith('Suggested · '));
    });
  }

  testWidgets('mild feelings and high calm get no suggestion', (tester) async {
    for (final (feeling, level) in [
      (CheckInFeeling.stressed, 4),
      (CheckInFeeling.calm, 10),
    ]) {
      await pump(
        tester,
        CheckInPrompt(
          key: ValueKey('$feeling'),
          onDone: (a, b, c, d) {},
          onSkip: () {},
        ),
      );
      await checkIn(tester, feeling, level);
      expect(find.text('What would you like to practise?'), findsOneWidget);
      expect(find.textContaining('Suggested'), findsNothing);
    }
  });

  test('calm is the only scale where a higher number is better', () {
    for (final feeling in CheckInFeeling.values) {
      expect(
        feeling.path.higherIsBetter,
        feeling == CheckInFeeling.calm,
        reason: feeling.name,
      );
      expect(
        feeling.path.suggestionFor(10) == null,
        feeling.path.higherIsBetter,
      );
      expect(feeling.path.suggestionFor(CheckInPath.strongFrom - 1), isNull);
    }
  });

  testWidgets('after the practice it asks again about the same feeling', (
    tester,
  ) async {
    int? after;
    await pump(
      tester,
      FeedbackPrompt(
        feeling: CheckInFeeling.distracted,
        levelBefore: 7,
        onDone: (mood, value, reflection) => after = value,
      ),
    );
    await tester.tap(find.text(Mood.good.label(english)));
    await tester.pumpAndSettle();

    expect(find.text('And how hard is it to focus now?'), findsOneWidget);
    expect(find.text('You started at 7.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    expect(after, 7);
  });

  testWidgets('skipping the check-in skips the follow-up scale too', (
    tester,
  ) async {
    await pump(
      tester,
      FeedbackPrompt(feeling: null, levelBefore: null, onDone: (a, b, c) {}),
    );
    await tester.tap(find.text(Mood.good.label(english)));
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsNothing);
    expect(
      find.text('What did you notice during the practice?'),
      findsOneWidget,
    );
  });
}
