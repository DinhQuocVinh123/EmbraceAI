import '../models/beat.dart';

/// Kịch bản buổi thiền 8 phút, khớp với `assets/video/meditation_8min.mp4`.
///
/// MỐC BEAT đo trực tiếp từ video: nhãn "Beat N" ở góc trên trái đổi đúng tại
/// các khung 1080, 1560, 2280, 3720, 5160, 6600, 8040, 9120, 10200, 11040
/// (24 fps) — tức các mốc tròn 45s, 65s, 95s, 155s, 215s, 275s, 335s, 380s,
/// 425s, 460s.
///
/// PHỤ ĐỀ khôi phục bằng OCR chính khung hình của video (chữ nung cứng vào
/// hình, không có file phụ đề rời), rồi soát lại từng câu. Mốc thời gian lấy
/// từ lúc chữ hiện ra và biến mất.
///
/// PHỤ ĐỀ TIẾNG VIỆT là bản nháp dịch từ câu tiếng Anh, giữ nguyên mốc thời
/// gian; nhóm nghiên cứu cần duyệt trước khi dùng với người tham gia thật.
/// Giọng tiếng Việt đọc đúng các câu này: sửa câu nào thì tạo lại giọng đọc
/// theo `tools/voice/README.md`.
///
/// Ba chỗ trong video vốn là câu hỏi kèm lựa chọn dạng `[ ... ]` thì KHÔNG
/// đưa vào đây — chúng trở thành nút bấm thật trong app (xem [BeatInteraction]).
class SessionScript {
  const SessionScript._();

  static const totalDuration = Duration(minutes: 8);

  /// Source timings stay unchanged so recorded narration and captions agree.
  static List<Beat> practiceBeats({
    bool breathingOnly = false,
    bool short = false,
  }) {
    final shortPlan = breathingOnly
        ? const {'arrival', 'breathing', 'present', 'closing'}
        : const {'arrival', 'grounding', 'breathing', 'closing'};
    return beats
        .where(
          (b) =>
              b.interaction == BeatInteraction.none &&
              !(breathingOnly && b.id == 'grounding') &&
              (!short || shortPlan.contains(b.id)),
        )
        .toList();
  }

  static Duration practiceDuration({
    bool breathingOnly = false,
    bool short = false,
  }) => practiceBeats(
    breathingOnly: breathingOnly,
    short: short,
  ).fold(Duration.zero, (sum, b) => sum + b.duration);

  static Duration _ms(num seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  static final List<Beat> beats = [
    Beat(
      number: 1,
      id: 'arrival',
      titleVi: 'Bắt đầu và định hướng',
      titleEn: 'Arrival and orientation',
      start: _ms(0),
      end: _ms(45),
      captions: [
        Caption(
          _ms(6),
          _ms(9.5),
          'Hello. Welcome.',
          'Xin chào. Chào mừng bạn.',
        ),
        Caption(
          _ms(12.5),
          _ms(16.5),
          'Thank you for taking a few minutes to pause.',
          'Cảm ơn bạn đã dành vài phút để dừng lại.',
        ),
        Caption(
          _ms(19.5),
          _ms(28.5),
          "I'll guide you through a short relaxation exercise using gentle "
              'breathing and present-moment awareness.',
          'Tôi sẽ hướng dẫn bạn một bài thư giãn ngắn, với hơi thở nhẹ nhàng và sự chú tâm vào hiện tại.',
        ),
        Caption(
          _ms(32.5),
          _ms(39),
          "You don't need any previous experience. There is nothing to "
              'achieve.',
          'Bạn không cần có kinh nghiệm trước. Không có gì phải đạt được cả.',
        ),
        Caption(
          _ms(41),
          _ms(45),
          'Simply follow along in whatever way feels comfortable.',
          'Bạn chỉ cần làm theo, theo cách nào thấy thoải mái.',
        ),
      ],
    ),
    Beat(
      number: 2,
      id: 'safety',
      titleVi: 'Kiểm tra an toàn',
      titleEn: 'Safety check',
      start: _ms(45),
      end: _ms(65),
      interaction: BeatInteraction.safetyCheck,
      captions: [
        Caption(
          _ms(46),
          _ms(51),
          'Before we begin, are you feeling comfortable enough to continue?',
          'Trước khi bắt đầu, bạn có thấy đủ thoải mái để tiếp tục không?',
        ),
      ],
    ),
    Beat(
      number: 3,
      id: 'checkin',
      titleVi: 'Hỏi thăm',
      titleEn: 'Check-in',
      start: _ms(65),
      end: _ms(95),
      interaction: BeatInteraction.moodCheckIn,
      captions: [
        Caption(
          _ms(66),
          _ms(69),
          'How are you feeling today?',
          'Hôm nay bạn thấy thế nào?',
        ),
        Caption(
          _ms(80),
          _ms(92),
          'Thank you for sharing that. Waiting for appointments or test '
              'results can bring understandable worries.',
          'Cảm ơn bạn đã chia sẻ. Chờ đến buổi khám hay chờ kết quả xét nghiệm có thể khiến ta lo lắng, và điều đó rất dễ hiểu.',
        ),
      ],
    ),
    Beat(
      number: 4,
      id: 'grounding',
      titleVi: 'Tiếp đất',
      titleEn: 'Grounding',
      start: _ms(95),
      end: _ms(155),
      skippable: true,
      // Lời gốc trong video giả định cách ngồi kiểu phương Tây — "place both
      // feet on the floor", "the chair supporting your body" — trong khi bối
      // cảnh là nhà cổ Việt Nam, suốt 8 phút không hề có cái ghế nào. Đây đúng
      // là chỗ Dr. Tuan và Dr. Silas nói "out of context". Video không có
      // giọng đọc (đã kiểm chứng bằng phân tích âm thanh), nên sửa chữ ở đây
      // là đủ — không lệch với bất cứ thứ gì người dùng nghe.
      captions: [
        Caption(
          _ms(96),
          _ms(100),
          'If it feels comfortable, let your body settle where you are.',
          'Nếu thấy thoải mái, hãy để cơ thể yên vị ở chỗ bạn đang ngồi.',
        ),
        Caption(
          _ms(108),
          _ms(112),
          'Notice the surface beneath you.',
          'Hãy cảm nhận bề mặt bên dưới bạn.',
        ),
        Caption(
          _ms(122),
          _ms(126),
          'Notice what is holding your weight right now.',
          'Cảm nhận thứ đang đỡ lấy cơ thể bạn lúc này.',
        ),
        Caption(
          _ms(136),
          _ms(140),
          'Allow your shoulders to soften if that feels comfortable.',
          'Nếu thấy thoải mái, hãy để đôi vai thả lỏng.',
        ),
        Caption(
          _ms(150),
          _ms(155),
          'There is no need to change anything. Simply notice.',
          'Không cần thay đổi điều gì. Chỉ cần nhận biết.',
        ),
      ],
    ),
    Beat(
      number: 5,
      id: 'breathing',
      titleVi: 'Thở thoải mái',
      titleEn: 'Comfortable breathing',
      start: _ms(155),
      end: _ms(215),
      // Đoạn này video không có phụ đề — chỉ có vòng tròn thở dẫn nhịp.
    ),
    Beat(
      number: 6,
      id: 'present',
      titleVi: 'Chú tâm hiện tại',
      titleEn: 'Present-moment awareness',
      start: _ms(215),
      end: _ms(275),
      captions: [
        Caption(
          _ms(217),
          _ms(220),
          'While waiting for appointments, our minds often become busy.',
          'Khi chờ đến buổi khám, tâm trí ta thường trở nên bận rộn.',
        ),
        Caption(
          _ms(225),
          _ms(232),
          'You may notice thoughts about your health, your medications, or '
              'your test results.',
          'Bạn có thể thấy những ý nghĩ về sức khoẻ, về thuốc men, hay về kết quả xét nghiệm.',
        ),
        Caption(
          _ms(240),
          _ms(244),
          'Whatever thoughts arise, it is natural for the mind to do this.',
          'Dù ý nghĩ nào xuất hiện, tâm trí làm vậy cũng là điều tự nhiên.',
        ),
        Caption(
          _ms(250),
          _ms(258),
          'Whenever you notice your attention drifting, gently bring it back '
              'to your breathing.',
          'Mỗi khi thấy sự chú ý trôi đi, hãy nhẹ nhàng đưa nó trở về với hơi thở.',
        ),
      ],
    ),
    Beat(
      number: 7,
      id: 'body',
      titleVi: 'Cảm nhận cơ thể',
      titleEn: 'Body awareness',
      start: _ms(275),
      end: _ms(335),
      skippable: true,
      captions: [
        Caption(
          _ms(276.5),
          _ms(280),
          'Now bring your attention to your body.',
          'Bây giờ, hãy đưa sự chú ý về cơ thể.',
        ),
        Caption(
          _ms(286),
          _ms(292),
          'Perhaps you notice warmth… coolness… or areas of tension.',
          'Có thể bạn nhận thấy hơi ấm… sự mát lạnh… hay những chỗ đang căng.',
        ),
        Caption(
          _ms(302),
          _ms(308),
          'Notice your forehead, and your jaw.',
          'Cảm nhận vầng trán, và quai hàm.',
        ),
        Caption(
          _ms(316),
          _ms(322),
          'Your shoulders, your arms, your hands. These hands have done a '
              'great deal today.',
          'Đôi vai, cánh tay, bàn tay. Đôi bàn tay này hôm nay đã làm được rất nhiều việc.',
        ),
        Caption(
          _ms(330),
          _ms(335),
          'There is no right or wrong experience. Simply notice.',
          'Không có trải nghiệm nào là đúng hay sai. Chỉ cần nhận biết.',
        ),
      ],
    ),
    Beat(
      number: 8,
      id: 'compassion',
      titleVi: 'Tử tế với chính mình',
      titleEn: 'Self-compassion',
      start: _ms(335),
      end: _ms(380),
      captions: [
        Caption(
          _ms(336),
          _ms(340),
          'Living with more than one health condition can be demanding.',
          'Sống chung với nhiều bệnh cùng lúc có thể rất vất vả.',
        ),
        Caption(
          _ms(346),
          _ms(350),
          'Many people experience uncertainty, fatigue, or frustration.',
          'Nhiều người cảm thấy bất an, mệt mỏi hay bực bội.',
        ),
        Caption(
          _ms(358),
          _ms(365),
          'See whether you can offer yourself the same kindness you would '
              'offer someone you care about.',
          'Hãy thử dành cho chính mình sự tử tế mà bạn vẫn dành cho người bạn thương.',
        ),
        Caption(
          _ms(369),
          _ms(373),
          'You might say quietly: May I care for myself today.',
          'Bạn có thể khẽ nói: Mong hôm nay tôi biết chăm sóc bản thân.',
        ),
        Caption(
          _ms(375),
          _ms(379),
          'May I meet this moment with patience.',
          'Mong tôi đón nhận khoảnh khắc này bằng sự kiên nhẫn.',
        ),
      ],
    ),
    Beat(
      number: 9,
      id: 'preparation',
      titleVi: 'Chuẩn bị cho buổi khám',
      titleEn: 'Healthcare preparation',
      start: _ms(380),
      end: _ms(425),
      interaction: BeatInteraction.openQuestion,
      captions: [
        Caption(
          _ms(381.75),
          _ms(384),
          'Before your next appointment, consider this.',
          'Trước buổi khám tới, hãy nghĩ về điều này.',
        ),
        Caption(
          _ms(388),
          _ms(393),
          'What is the most important thing you would like your healthcare '
              'team to understand about you?',
          'Điều quan trọng nhất bạn muốn nhóm chăm sóc sức khoẻ hiểu về mình là gì?',
        ),
        Caption(
          _ms(403),
          _ms(407),
          'Is there one question you would like answered?',
          'Bạn có câu hỏi nào muốn được giải đáp không?',
        ),
        Caption(
          _ms(417),
          _ms(422),
          "You don't need to solve everything today. One important concern "
              'is enough.',
          'Bạn không cần giải quyết mọi việc trong hôm nay. Một điều quan trọng là đủ.',
        ),
      ],
    ),
    Beat(
      number: 10,
      id: 'closing',
      titleVi: 'Khép lại',
      titleEn: 'Closing',
      start: _ms(425),
      end: _ms(460),
      captions: [
        Caption(
          _ms(427),
          _ms(429),
          'Move your fingers and toes a little.',
          'Hãy cử động nhẹ các ngón tay và ngón chân.',
        ),
        Caption(
          _ms(435),
          _ms(438),
          'Thank you for practising with me today.',
          'Cảm ơn bạn đã cùng tập với tôi hôm nay.',
        ),
        Caption(
          _ms(443),
          _ms(449),
          'Even a few moments of slowing down can become part of caring for '
              'yourself.',
          'Chỉ vài phút chậm lại cũng có thể trở thành một phần của việc chăm sóc bản thân.',
        ),
        Caption(
          _ms(455),
          _ms(458),
          "I hope you'll join me again soon.",
          'Mong sớm gặp lại bạn.',
        ),
      ],
    ),
    Beat(
      number: 11,
      id: 'feedback',
      titleVi: 'Cảm nhận sau buổi tập',
      titleEn: 'After-session feedback',
      start: _ms(460),
      end: _ms(480),
      interaction: BeatInteraction.feedback,
      captions: [
        Caption(
          _ms(461),
          _ms(464),
          'How do you feel now?',
          'Bây giờ bạn thấy thế nào?',
        ),
      ],
    ),
  ];

  static Beat beatAt(Duration position) {
    for (final beat in beats) {
      if (beat.containsAt(position)) return beat;
    }
    return beats.last;
  }

  static Beat? next(Beat beat) {
    final i = beats.indexOf(beat);
    return i >= 0 && i < beats.length - 1 ? beats[i + 1] : null;
  }

  /// Tổng thời lượng khi bỏ các beat có thể lược bớt — dùng cho bản rút gọn.
  static Duration get shortDuration => beats
      .where((b) => !b.skippable)
      .fold(Duration.zero, (sum, b) => sum + b.duration);

  /// Tổng số câu phụ đề — dùng để biết kịch bản đã đủ chưa.
  static int get captionCount =>
      beats.fold(0, (sum, b) => sum + b.captions.length);
}
