import 'package:embrace_ai/models/mood.dart';
import 'package:embrace_ai/widgets/mood_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MoodPicker hiện đủ năm mức và báo về mức được chọn',
      (tester) async {
    Mood? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoodPicker(
            selected: Mood.neutral,
            onChanged: (mood) => picked = mood,
          ),
        ),
      ),
    );

    for (final mood in Mood.values) {
      expect(find.text(mood.label), findsOneWidget);
    }

    await tester.tap(find.text(Mood.great.label));
    expect(picked, Mood.great);
  });
}
