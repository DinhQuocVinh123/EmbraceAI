/// Một câu phụ đề kèm khoảng thời gian nó xuất hiện.
class Caption {
  const Caption(this.start, this.end, this.text);

  final Duration start;
  final Duration end;
  final String text;

  bool coversAt(Duration position) => position >= start && position < end;
}

/// Kiểu tương tác app chen vào ở cuối một beat.
///
/// Trong bản video hiện tại các câu hỏi này chỉ là chữ nung vào hình, người
/// xem không trả lời được. Đây chính là chỗ hội đồng muốn biến thành tương
/// tác thật (Dr. Annie, Prof. Annie Chang).
enum BeatInteraction {
  /// Chạy hết beat rồi đi tiếp, không hỏi gì.
  none,

  /// "Bạn có đang ở nơi an toàn để tiếp tục không?" — Có / Không chắc / Không.
  safetyCheck,

  /// "Hôm nay bạn thấy thế nào?" — chọn một trạng thái.
  moodCheckIn,

  /// Thang căng thẳng 0–10, dùng để chọn bài phù hợp.
  stressScale,

  /// Câu hỏi mở, người dùng tự gõ.
  openQuestion,

  /// Phản hồi sau buổi tập.
  feedback,
}

/// Một đoạn của buổi thiền, ứng với một "Beat" trong video gốc.
class Beat {
  const Beat({
    required this.number,
    required this.id,
    required this.titleVi,
    required this.titleEn,
    required this.start,
    required this.end,
    this.interaction = BeatInteraction.none,
    this.skippable = false,
    this.captions = const [],
  });

  final int number;
  final String id;
  final String titleVi;
  final String titleEn;

  /// Nhãn hiện lên màn hình.
  ///
  /// App đang chạy tiếng Anh. Giữ một chỗ duy nhất chọn ngôn ngữ, thay vì để
  /// mỗi màn hình tự với tay vào [titleVi] hay [titleEn] — đã có lần màn hình
  /// thiền lấy nhầm bản tiếng Việt và không test nào bắt được, vì test ảnh
  /// truyền thẳng chuỗi tiếng Anh vào chứ không đi qua đây.
  String get title => titleEn;
  final Duration start;
  final Duration end;
  final BeatInteraction interaction;

  /// Beat có thể bỏ qua khi rút ngắn buổi tập theo lựa chọn của người dùng.
  final bool skippable;

  final List<Caption> captions;

  Duration get duration => end - start;

  bool containsAt(Duration position) => position >= start && position < end;

  /// Câu phụ đề đang hiển thị tại [position], null nếu lúc đó không có câu nào.
  Caption? captionAt(Duration position) {
    for (final caption in captions) {
      if (caption.coversAt(position)) return caption;
    }
    return null;
  }
}
