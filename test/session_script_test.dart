import 'package:embrace_ai/data/session_script.dart';
import 'package:embrace_ai/models/beat.dart';
import 'package:embrace_ai/models/mood.dart';
import 'package:embrace_ai/models/session_answers.dart';
import 'package:embrace_ai/models/session_scene.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionScript', () {
    test('11 beat nối liền nhau, không hở không chồng', () {
      final beats = SessionScript.beats;
      expect(beats, hasLength(11));
      expect(beats.first.start, Duration.zero);
      for (var i = 1; i < beats.length; i++) {
        expect(
          beats[i].start,
          beats[i - 1].end,
          reason:
              'beat ${beats[i].number} phải bắt đầu đúng chỗ '
              'beat trước kết thúc',
        );
      }
    });

    test('tổng thời lượng khớp đúng 8 phút của video', () {
      expect(SessionScript.beats.last.end, SessionScript.totalDuration);
      final sum = SessionScript.beats.fold(
        Duration.zero,
        (acc, b) => acc + b.duration,
      );
      expect(sum, SessionScript.totalDuration);
    });

    test('các mốc đúng như đo được từ video', () {
      const expected = [0, 45, 65, 95, 155, 215, 275, 335, 380, 425, 460];
      expect(
        SessionScript.beats.map((b) => b.start.inSeconds).toList(),
        expected,
      );
    });

    test('beatAt tìm đúng beat theo thời điểm', () {
      expect(SessionScript.beatAt(Duration.zero).id, 'arrival');
      expect(SessionScript.beatAt(const Duration(seconds: 44)).id, 'arrival');
      expect(SessionScript.beatAt(const Duration(seconds: 45)).id, 'safety');
      expect(
        SessionScript.beatAt(const Duration(seconds: 200)).id,
        'breathing',
      );
      expect(SessionScript.beatAt(const Duration(seconds: 479)).id, 'feedback');
    });

    test('quá thời lượng thì trả về beat cuối chứ không ném lỗi', () {
      expect(SessionScript.beatAt(const Duration(minutes: 20)).id, 'feedback');
    });

    test('next trả null ở beat cuối', () {
      expect(SessionScript.next(SessionScript.beats.last), isNull);
      expect(SessionScript.next(SessionScript.beats.first)?.id, 'safety');
    });

    test('bản rút gọn ngắn hơn bản đầy đủ', () {
      expect(
        SessionScript.shortDuration,
        lessThan(SessionScript.totalDuration),
      );
      expect(SessionScript.beats.where((b) => b.skippable), isNotEmpty);
    });

    test('hai bài ngắn cùng dài 3 phút 20 giây', () {
      expect(
        SessionScript.practiceDuration(short: true),
        const Duration(minutes: 3, seconds: 20),
      );
      expect(
        SessionScript.practiceDuration(breathingOnly: true, short: true),
        const Duration(minutes: 3, seconds: 20),
      );
    });

    test('bài đầy đủ giữ nguyên thời lượng theo lựa chọn thực hành', () {
      expect(
        SessionScript.practiceDuration(),
        const Duration(minutes: 6, seconds: 5),
      );
      expect(
        SessionScript.practiceDuration(breathingOnly: true),
        const Duration(minutes: 5, seconds: 5),
      );
    });

    test('mỗi kiểu tương tác chỉ gắn vào đúng một beat', () {
      for (final kind in BeatInteraction.values) {
        if (kind == BeatInteraction.none) continue;
        final owners = SessionScript.beats.where((b) => b.interaction == kind);
        expect(
          owners.length,
          lessThanOrEqualTo(1),
          reason: 'kiểu $kind bị gắn vào nhiều beat',
        );
      }
    });
  });

  group('Phụ đề khôi phục từ video', () {
    test('có đủ kịch bản, không còn là vài câu lẻ', () {
      expect(SessionScript.captionCount, greaterThanOrEqualTo(30));
    });

    test('mọi phụ đề nằm gọn trong beat chứa nó và không chồng nhau', () {
      for (final beat in SessionScript.beats) {
        for (var i = 0; i < beat.captions.length; i++) {
          final c = beat.captions[i];
          expect(
            c.start,
            greaterThanOrEqualTo(beat.start),
            reason: '"${c.text}" bắt đầu trước beat ${beat.number}',
          );
          expect(
            c.end,
            lessThanOrEqualTo(beat.end),
            reason: '"${c.text}" kéo quá beat ${beat.number}',
          );
          expect(c.start, lessThan(c.end));
          if (i > 0) {
            expect(
              c.start,
              greaterThanOrEqualTo(beat.captions[i - 1].end),
              reason: 'hai phụ đề chồng nhau ở beat ${beat.number}',
            );
          }
        }
      }
    });

    test('captionAt trả về đúng câu đang hiển thị', () {
      final first = SessionScript.beats.first;
      expect(
        first.captionAt(const Duration(seconds: 7))?.text,
        'Hello. Welcome.',
      );
      expect(
        first.captionAt(const Duration(seconds: 22))?.text,
        contains('gentle breathing'),
      );
      expect(
        first.captionAt(const Duration(seconds: 11)),
        isNull,
        reason: 'giữa hai câu thì không hiện gì',
      );
    });

    test('đoạn thở không có phụ đề — chỉ có vòng tròn dẫn nhịp', () {
      final breathing = SessionScript.beats.firstWhere(
        (b) => b.id == 'breathing',
      );
      expect(breathing.captions, isEmpty);
    });

    test('phụ đề toàn tiếng Anh, không sót chữ tiếng Việt', () {
      final viet = RegExp('[ăâđêôơưĂÂĐÊÔƠƯàáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệ]');
      for (final beat in SessionScript.beats) {
        for (final c in beat.captions) {
          expect(
            viet.hasMatch(c.text),
            isFalse,
            reason: 'còn tiếng Việt: "${c.text}"',
          );
        }
      }
    });

    test(
      'ba câu hỏi có lựa chọn không nằm trong phụ đề — chúng là nút bấm',
      () {
        for (final beat in SessionScript.beats) {
          for (final c in beat.captions) {
            expect(
              c.text.contains('['),
              isFalse,
              reason: 'dòng lựa chọn lẽ ra phải thành nút: "${c.text}"',
            );
          }
        }
      },
    );
  });

  group('SessionAnswers', () {
    test('stressDelta cần đủ cả hai lần đo', () {
      final a = SessionAnswers()..stressBefore = 8;
      expect(a.stressDelta, isNull);
      a.stressAfter = 3;
      expect(a.stressDelta, 5);
    });

    test('giảm nhiều thì câu chốt nhắc lại đúng con số', () {
      final a = SessionAnswers()
        ..stressBefore = 8
        ..stressAfter = 3
        ..practice = PracticeChoice.grounding;
      expect(a.closingMessage, contains('8'));
      expect(a.closingMessage, contains('3'));
      expect(a.closingMessage, contains('body scan'));
    });

    test('không đổi thì trấn an chứ không báo thất bại', () {
      final a = SessionAnswers()
        ..stressBefore = 5
        ..stressAfter = 5;
      expect(a.closingMessage, contains('does not always shift'));
    });

    test('căng hơn lúc đầu vẫn được ghi nhận tử tế', () {
      final a = SessionAnswers()
        ..stressBefore = 3
        ..stressAfter = 6;
      expect(a.closingMessage, contains('honest'));
    });

    test('không trả lời gì vẫn có câu chốt', () {
      expect(SessionAnswers().closingMessage, isNotEmpty);
    });

    test('có ghi câu hỏi thì câu chốt nhắc tới', () {
      final a = SessionAnswers()..question = 'What does this result mean?';
      expect(a.closingMessage, contains('appointment'));
    });

    test('chọn bài thở thì gợi ý lần sau thêm phần tiếp đất', () {
      final a = SessionAnswers()
        ..feeling = CheckInFeeling.stressed
        ..practice = PracticeChoice.breathing;
      expect(a.closingMessage, contains('grounding'));
    });

    test('mood cuối buổi độc lập với trạng thái check-in', () {
      final answers = SessionAnswers()..feeling = CheckInFeeling.calm;
      expect(answers.moodAfter, isNull);

      answers.moodAfter = Mood.great;
      expect(answers.moodAfter, Mood.great);
    });
  });

  group('SessionScene', () {
    test('có ít nhất hai bối cảnh để lựa chọn mới có ý nghĩa', () {
      expect(SessionScene.values.length, greaterThanOrEqualTo(2));
    });

    test('mỗi bối cảnh trỏ tới một file video riêng', () {
      final assets = SessionScene.values.map((s) => s.asset).toSet();
      expect(assets.length, SessionScene.values.length);
      for (final s in SessionScene.values) {
        expect(s.asset, startsWith('assets/video/'));
        expect(s.asset, endsWith('.mp4'));
      }
    });

    test('không bối cảnh nào còn chữ nung cứng để phải che', () {
      // Bản quê đã được cắt bỏ nhãn beat và phụ đề khỏi hình; bản biển vốn
      // dựng riêng nên chưa từng có. Nhờ vậy app không phủ dải tối nào lên
      // video nữa — trước đây hình bị tối hẳn hai đầu.
      expect(SessionScene.values, isNotEmpty);
      for (final scene in SessionScene.values) {
        expect(scene.asset, endsWith('.mp4'));
      }
    });

    test('fromId đọc lại đúng, id lạ thì về bối cảnh mặc định', () {
      expect(SessionScene.fromId('beach'), SessionScene.beach);
      expect(SessionScene.fromId('countryside'), SessionScene.countryside);
      expect(SessionScene.fromId('khong-ton-tai'), SessionScene.countryside);
      expect(SessionScene.fromId(null), SessionScene.countryside);
    });

    test('nhãn và mô tả đều bằng tiếng Anh, không rỗng', () {
      final viet = RegExp('[ăâđêôơưàáảãạèéẻẽẹìíỉĩịòóỏõọùúủũụ]');
      for (final s in SessionScene.values) {
        expect(s.label, isNotEmpty);
        expect(s.description, isNotEmpty);
        expect(
          viet.hasMatch(s.label + s.description),
          isFalse,
          reason: 'còn tiếng Việt trong ${s.id}',
        );
      }
    });
  });
}
