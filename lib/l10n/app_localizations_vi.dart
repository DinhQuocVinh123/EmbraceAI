// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get languageTitle => 'Ngôn ngữ';

  @override
  String get languagePhone => 'Theo điện thoại';

  @override
  String get languageButtonTooltip => 'Ngôn ngữ';

  @override
  String get languageVoiceNote =>
      'Giọng hướng dẫn, phụ đề và mọi phần khác của app đều theo ngôn ngữ bạn chọn.';

  @override
  String get commonOpen => 'Mở';

  @override
  String get commonCancel => 'Huỷ';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonBack => 'Quay lại';

  @override
  String get commonNext => 'Tiếp';

  @override
  String get commonDone => 'Xong';

  @override
  String get commonTryAgain => 'Thử lại';

  @override
  String get commonClose => 'Đóng';

  @override
  String get homeSignOut => 'Đăng xuất';

  @override
  String get homeNewEntry => 'Ghi chú mới';

  @override
  String get homeTabSession => 'Buổi tập';

  @override
  String get homeTabJournal => 'Nhật ký';

  @override
  String get homeTabInsights => 'Thống kê';

  @override
  String get homeFinalReady => 'Bảng câu hỏi cuối đã sẵn sàng';

  @override
  String get welcomeTitle => 'Một phút tĩnh lặng';

  @override
  String get welcomeIntro =>
      'Bài thư giãn có hướng dẫn, dành cho những lúc quanh buổi khám và khi chờ kết quả xét nghiệm. Bạn chỉ cần ngồi yên và làm theo.';

  @override
  String get welcomeSessionSaved => 'Đã lưu buổi tập vào nhật ký';

  @override
  String journalLineQuestion(String question) {
    return 'Câu hỏi cho nhóm chăm sóc: $question';
  }

  @override
  String journalLineLevel(String name, int before, int after) {
    return '$name: $before → $after';
  }

  @override
  String get welcomeAskTitle => 'Hỏi EmbraceAI (bản thử)';

  @override
  String get welcomeAskSubtitle => 'Câu hỏi về bài tập hoặc về app';

  @override
  String get welcomeBegin => 'Bắt đầu';

  @override
  String get welcomeStopAnyTime => 'Bạn có thể dừng bất cứ lúc nào.';

  @override
  String get welcomeEasierTitle => 'Dễ nhìn hơn';

  @override
  String get welcomeEasierBody =>
      'Nếu chữ nhỏ khó đọc hoặc hình trông mờ, hãy bật chế độ này.';

  @override
  String get welcomeEasierOn => 'Đang bật chế độ dễ nhìn';

  @override
  String get welcomeEasierTurnOn => 'Bật chế độ dễ nhìn';

  @override
  String get welcomeExpectTimeTitle => 'Chọn 3 phút hoặc 5 đến 6 phút';

  @override
  String get welcomeExpectTimeBody => 'Một chút thời gian cho riêng bạn';

  @override
  String get welcomeExpectFlowTitle => 'Trước và sau';

  @override
  String get welcomeExpectFlowBody =>
      'Hỏi thăm ngắn, tập liền một mạch, rồi dành thời gian nghĩ lại';

  @override
  String get welcomeExpectHeadphonesTitle => 'Tai nghe sẽ giúp ích';

  @override
  String get welcomeExpectHeadphonesBody => 'Nhưng không bắt buộc';

  @override
  String get welcomeExpectStopTitle => 'Dừng bất cứ lúc nào';

  @override
  String get welcomeExpectStopBody => 'Không mất gì cả';

  @override
  String get welcomeSceneTitle => 'Khung cảnh';

  @override
  String get welcomeSceneBody =>
      'Chọn khung cảnh bạn muốn ngắm. Bài tập thì vẫn như nhau.';

  @override
  String get welcomeSoundDisplayTitle => 'Âm thanh và hiển thị';

  @override
  String get welcomeTextSize => 'Cỡ chữ';

  @override
  String percentValue(int percent) {
    return '$percent%';
  }

  @override
  String get welcomeShowCaptions => 'Hiện phụ đề';

  @override
  String get welcomeShowCaptionsBody =>
      'Hiện thành chữ những gì đang được nói, theo cỡ chữ bạn chọn';

  @override
  String get welcomeReduceMotion => 'Giảm chuyển động';

  @override
  String get welcomeReduceMotionBody =>
      'Bỏ các hiệu ứng mờ dần và chuyển trang không cần thiết';

  @override
  String durationMinSec(int minutes, int seconds) {
    return '$minutes phút $seconds giây';
  }

  @override
  String welcomeDurations(String short, String full, String breathing) {
    return 'Ngắn $short · Đầy đủ $full với bài tiếp đất, hoặc $breathing với bài hít thở';
  }

  @override
  String get welcomeSummaryVoiceOn => 'Bật giọng đọc';

  @override
  String get welcomeSummaryVoiceOff => 'Tắt giọng đọc';

  @override
  String welcomeSummaryText(int percent) {
    return 'Chữ $percent%';
  }

  @override
  String get welcomeSummaryCaptionsOn => 'Bật phụ đề';

  @override
  String get welcomeSummaryCaptionsOff => 'Tắt phụ đề';

  @override
  String get sceneCountryside => 'Làng quê Việt Nam';

  @override
  String get sceneCountrysideDescription =>
      'Sân nhà lúc bình minh, mặt nước lặng và con đường làng yên ả';

  @override
  String get sceneBeach => 'Bãi biển, từ bình minh đến đêm';

  @override
  String get sceneBeachDescription =>
      'Chân trời rộng mở, sóng chậm, ánh sáng đổi dần trong ngày';

  @override
  String get soundMatchVideo => 'Theo video';

  @override
  String get soundMatchVideoDescription =>
      'Nhạc đồng quê hoặc tiếng sóng biển, chọn theo hình';

  @override
  String get soundNone => 'Không có';

  @override
  String get soundNoneDescription => 'Chỉ có giọng hướng dẫn, không có âm nền';

  @override
  String get soundCountryside => 'Đồng quê';

  @override
  String get soundCountrysideDescription =>
      'Nhạc không lời nhẹ nhàng, mang không khí đồng quê';

  @override
  String get soundOcean => 'Sóng biển';

  @override
  String get soundOceanDescription => 'Sóng chậm và gió biển nhẹ';

  @override
  String get soundRain => 'Mưa nhẹ';

  @override
  String get soundRainDescription => 'Mưa đều, không có sấm';

  @override
  String get levelQuiet => 'Nhỏ';

  @override
  String get levelQuietDescription => 'Âm lượng nhỏ';

  @override
  String get levelNormal => 'Vừa';

  @override
  String get levelNormalDescription => 'Âm lượng vừa phải';

  @override
  String get levelLouder => 'To hơn';

  @override
  String get levelLouderDescription => 'Âm lượng tối đa';

  @override
  String get moodAwful => 'Rất khó khăn';

  @override
  String get moodLow => 'Không được tốt';

  @override
  String get moodNeutral => 'Bình thường';

  @override
  String get moodGood => 'Khá tốt';

  @override
  String get moodGreat => 'Rất tốt';

  @override
  String get feelingCalm => 'Bình tĩnh';

  @override
  String get feelingStressed => 'Căng thẳng';

  @override
  String get feelingTired => 'Mệt mỏi';

  @override
  String get feelingUpset => 'Buồn bực';

  @override
  String get feelingDistracted => 'Khó tập trung';

  @override
  String get safetyYes => 'Có, tôi có thể ngồi yên';

  @override
  String get safetyUnsure => 'Tôi không chắc';

  @override
  String get safetyNo => 'Lúc này thì chưa';

  @override
  String get practiceGrounding => 'Tiếp đất';

  @override
  String get practiceGroundingDescription =>
      'Cảm nhận chỗ dựa bên dưới bạn, rồi theo dõi hơi thở';

  @override
  String get practiceBreathing => 'Theo dõi hơi thở';

  @override
  String get practiceBreathingDescription => 'Vào thẳng bài tập hít thở';

  @override
  String get lengthShort => 'Bài ngắn';

  @override
  String get lengthShortDescription => 'Khoảng 3 phút';

  @override
  String get lengthFull => 'Bài đầy đủ';

  @override
  String get lengthFullDescription => 'Khoảng 5 đến 6 phút';

  @override
  String get breatheIn => 'Hít vào';

  @override
  String get breatheOut => 'Thở ra';

  @override
  String get commonContinue => 'Tiếp tục';

  @override
  String get promptSkipQuestion => 'Bỏ qua câu này';

  @override
  String get disclaimerTitle => 'Lưu ý về y tế';

  @override
  String get disclaimerSubtitle => 'Vui lòng đọc trước mỗi buổi tập.';

  @override
  String get disclaimerBody =>
      'Đây không phải là một biện pháp điều trị y tế. Nếu bạn thấy khó chịu, hãy dừng ngay và tìm sự giúp đỡ từ nhóm y tế của bạn.';

  @override
  String get disclaimerAccept => 'Tôi đã hiểu, tiếp tục';

  @override
  String get disclaimerLeave => 'Rời buổi tập';

  @override
  String get safetyTitle => 'Bạn có thấy đủ thoải mái để tiếp tục không?';

  @override
  String get safetyBody =>
      'Bài tập này cần bạn ở một nơi an toàn. Vui lòng không tập khi đang lái xe hoặc vận hành máy móc.';

  @override
  String get checkInFeelingTitle => 'Lúc này bạn thấy thế nào?';

  @override
  String get checkInScaleSubtitle =>
      'Kéo thanh trượt đến con số hợp với bạn nhất.';

  @override
  String get checkInSuggested => 'Gợi ý';

  @override
  String get checkInGentleTitle => 'Mình tập nhẹ nhàng thôi nhé';

  @override
  String get checkInCalmScaleTitle => 'Lúc này bạn thấy bình tâm đến mức nào?';

  @override
  String get checkInCalmScaleLow => '0 · không bình tâm chút nào';

  @override
  String get checkInCalmScaleHigh => '10 · hoàn toàn bình tâm';

  @override
  String get checkInCalmAfterTitle =>
      'Còn bây giờ bạn thấy bình tâm đến mức nào?';

  @override
  String get checkInCalmName => 'Bình tâm';

  @override
  String get checkInCalmMeasure => 'bình tâm';

  @override
  String get checkInStressedScaleTitle =>
      'Lúc này bạn thấy căng thẳng đến mức nào?';

  @override
  String get checkInStressedScaleLow => '0 · thoải mái';

  @override
  String get checkInStressedScaleHigh => '10 · rất căng thẳng';

  @override
  String get checkInStressedAfterTitle =>
      'Còn mức căng thẳng của bạn bây giờ thì sao?';

  @override
  String get checkInStressedName => 'Căng thẳng';

  @override
  String get checkInStressedMeasure => 'căng thẳng';

  @override
  String get checkInStressedStrongBody =>
      'Lúc này bạn đang mang nhiều căng thẳng. Bài tiếp đất thường giúp bạn lắng lại nhanh hơn.';

  @override
  String get checkInTiredScaleTitle => 'Lúc này bạn thấy mệt đến mức nào?';

  @override
  String get checkInTiredScaleLow => '0 · đầy năng lượng';

  @override
  String get checkInTiredScaleHigh => '10 · kiệt sức';

  @override
  String get checkInTiredAfterTitle => 'Còn bây giờ bạn thấy mệt đến mức nào?';

  @override
  String get checkInTiredName => 'Mệt mỏi';

  @override
  String get checkInTiredMeasure => 'mệt mỏi';

  @override
  String get checkInTiredStrongBody =>
      'Lúc này bạn đang ít năng lượng. Chỉ cần theo dõi hơi thở thường đã đủ.';

  @override
  String get checkInUpsetScaleTitle =>
      'Cảm giác buồn bực lúc này mạnh đến mức nào?';

  @override
  String get checkInUpsetScaleLow => '0 · không có';

  @override
  String get checkInUpsetScaleHigh => '10 · rất mạnh';

  @override
  String get checkInUpsetAfterTitle =>
      'Còn bây giờ cảm giác đó mạnh đến mức nào?';

  @override
  String get checkInUpsetName => 'Buồn bực';

  @override
  String get checkInUpsetMeasure => 'buồn bực';

  @override
  String get checkInUpsetStrongBody =>
      'Lúc này chắc hẳn không dễ chịu. Bài tiếp đất có thể giúp những cảm xúc mạnh lắng xuống.';

  @override
  String get checkInDistractedScaleTitle =>
      'Lúc này bạn thấy khó tập trung đến mức nào?';

  @override
  String get checkInDistractedScaleLow => '0 · tập trung dễ dàng';

  @override
  String get checkInDistractedScaleHigh => '10 · rất khó tập trung';

  @override
  String get checkInDistractedAfterTitle =>
      'Còn bây giờ bạn thấy khó tập trung đến mức nào?';

  @override
  String get checkInDistractedName => 'Khó tập trung';

  @override
  String get checkInDistractedMeasure => 'khó tập trung';

  @override
  String get checkInDistractedStrongBody =>
      'Tâm trí bạn đang bận rộn. Bài tiếp đất giúp đưa sự chú ý trở về với hiện tại.';

  @override
  String get checkInSlowerTitle => 'Mình đi chậm lại một chút nhé';

  @override
  String get checkInChooseTitle => 'Bạn muốn tập bài nào?';

  @override
  String get checkInLengthTitle => 'Bạn muốn tập trong bao lâu?';

  @override
  String get checkInLengthSubtitle =>
      'Cả hai lựa chọn đều kết thúc bằng một khoảng để nghĩ lại.';

  @override
  String get questionTitle => 'Bạn có câu hỏi nào muốn được giải đáp không?';

  @override
  String get questionSubtitle =>
      'Hãy ghi lại ở đây để mang theo trong buổi khám tới.';

  @override
  String get questionLabel => 'Câu hỏi cho nhóm chăm sóc của bạn';

  @override
  String get questionHint =>
      'Ví dụ: điều này sẽ ảnh hưởng thế nào đến sinh hoạt hằng ngày của tôi?';

  @override
  String get questionSave => 'Lưu và tiếp tục';

  @override
  String get feedbackMoodTitle => 'Bây giờ bạn thấy thế nào?';

  @override
  String get feedbackMoodSubtitle =>
      'Chọn câu gần nhất với cảm nhận của bạn. Không có câu trả lời đúng hay sai.';

  @override
  String feedbackLevelStarted(int value) {
    return 'Lúc đầu bạn chọn $value.';
  }

  @override
  String get feedbackNoticeTitle => 'Trong lúc tập, bạn nhận thấy điều gì?';

  @override
  String get feedbackNoticeSubtitle =>
      'Một câu là đủ. Không có câu trả lời đúng hay sai.';

  @override
  String get feedbackNoticeLabel => 'Điều bạn nhận thấy';

  @override
  String get feedbackNoticeHint =>
      'Ví dụ: vai tôi thả lỏng hơn, hơi thở chậm dần về cuối.';

  @override
  String levelOutOfTen(int value) {
    return '$value trên 10';
  }

  @override
  String get helpTitle => 'Trợ giúp';

  @override
  String get helpClose => 'Đóng trợ giúp';

  @override
  String get helpBody =>
      'Cứ từ từ. Hãy tìm một tư thế thoải mái và để hơi thở tự nhiên. Bạn có thể rời buổi tập bất cứ khi nào cần.';

  @override
  String get helpEasierView => 'Chế độ dễ nhìn';

  @override
  String get helpBrighterPicture => 'Hình sáng hơn';

  @override
  String get helpReturn => 'Quay lại buổi tập';

  @override
  String get helpEnd => 'Kết thúc buổi tập';

  @override
  String get soundGuidedVoice => 'Giọng hướng dẫn';

  @override
  String get soundGuidedVoiceBody =>
      'Lời hướng dẫn đọc thành tiếng trong lúc tập';

  @override
  String get soundVoiceVolume => 'Âm lượng giọng đọc';

  @override
  String get soundBackground => 'Âm nền';

  @override
  String get soundBackgroundBody =>
      'Phát riêng, không ảnh hưởng giọng hướng dẫn';

  @override
  String get soundStopPreview => 'Dừng nghe thử';

  @override
  String get soundPreview => 'Nghe thử';

  @override
  String get soundBackgroundVolume => 'Âm lượng âm nền';

  @override
  String get soundLow => 'Thấp';

  @override
  String get soundMedium => 'Vừa';

  @override
  String get soundHigh => 'Cao';

  @override
  String get soundPreviewFailed => 'Không phát thử được âm thanh.';

  @override
  String get reflectAnother => 'Câu hỏi khác';

  @override
  String get reflectAwful1 =>
      'Lúc này điều gì đè nặng lên bạn nhất? Thử gọi tên nó xem.';

  @override
  String get reflectAwful2 =>
      'Nếu một người bạn gặp đúng chuyện này, bạn sẽ nói gì với họ?';

  @override
  String get reflectAwful3 =>
      'Có việc nhỏ nào bạn làm được ngay bây giờ để thấy nhẹ lòng hơn một chút không?';

  @override
  String get reflectLow1 => 'Hôm nay có chuyện gì làm bạn thấy hao sức?';

  @override
  String get reflectLow2 =>
      'Cơ thể đang nói gì với bạn — mệt, đói hay thiếu ngủ?';

  @override
  String get reflectLow3 =>
      'Có điều gì bạn đang đòi hỏi ở bản thân mà có thể để sau không?';

  @override
  String get reflectNeutral1 => 'Chi tiết nhỏ nào của hôm nay đáng để nhớ?';

  @override
  String get reflectNeutral2 =>
      'Hôm nay phần lớn thời gian của bạn dành cho việc gì?';

  @override
  String get reflectNeutral3 =>
      'Nếu ngày mai giống hệt hôm nay, bạn sẽ muốn thay đổi điều gì?';

  @override
  String get reflectGood1 => 'Hôm nay điều gì diễn ra suôn sẻ?';

  @override
  String get reflectGood2 => 'Ai đã giúp hôm nay nhẹ nhàng hơn?';

  @override
  String get reflectGood3 => 'Thói quen nào của bạn đang thật sự có ích?';

  @override
  String get reflectGreat1 => 'Khoảnh khắc nào làm nên ngày hôm nay?';

  @override
  String get reflectGreat2 =>
      'Từ hôm nay, bạn muốn giữ lại điều gì cho những ngày khó khăn hơn?';

  @override
  String get reflectGreat3 =>
      'Bạn đã làm được điều gì khiến chính bạn cũng bất ngờ?';

  @override
  String get tagAppointment => 'Buổi khám';

  @override
  String get tagFamily => 'Gia đình';

  @override
  String get tagFriends => 'Bạn bè';

  @override
  String get tagHealth => 'Sức khoẻ';

  @override
  String get tagWork => 'Công việc';

  @override
  String get tagRest => 'Nghỉ ngơi';

  @override
  String get tagExercise => 'Tập thể dục';

  @override
  String get tagAlone => 'Một mình';

  @override
  String get tagSession => 'Buổi tập';

  @override
  String get tagSynced => 'Đã đồng bộ';

  @override
  String closingLevelBetter(String measure, int before, int after) {
    return 'Mức $measure của bạn đi từ $before đến $after.';
  }

  @override
  String closingLevelBetterLittle(String measure, int before, int after) {
    return 'Mức $measure của bạn thay đổi một chút, từ $before đến $after.';
  }

  @override
  String closingLevelSame(String measure, int value) {
    return 'Mức $measure của bạn vẫn ở $value. Chuyện này vẫn thường gặp — một buổi tập không phải lúc nào cũng thay đổi được ngay.';
  }

  @override
  String get closingLevelWorse =>
      'Lúc này bạn thấy khó chịu hơn lúc bắt đầu một chút. Cảm ơn bạn đã thành thật về điều đó.';

  @override
  String get closingNextBodyScan =>
      'Lần tới, một bài quét cơ thể ngắn có thể hợp với bạn.';

  @override
  String get closingNextGrounding =>
      'Lần tới, hãy thử thêm phần tiếp đất ở đầu buổi xem có giúp bạn lắng lại không.';

  @override
  String get closingQuestionSaved =>
      'Câu hỏi bạn ghi lại đã được lưu cho buổi khám tới.';

  @override
  String get closingThanks => 'Cảm ơn bạn đã dành thời gian cho buổi tập này.';

  @override
  String get sessionBeforeTitle => 'Trước khi bắt đầu';

  @override
  String get sessionAfterTitle => 'Sau buổi tập';

  @override
  String get sessionStopTitle => 'Dừng buổi tập?';

  @override
  String get sessionStopBody => 'Bạn có thể quay lại bất cứ lúc nào.';

  @override
  String get sessionKeepGoing => 'Tập tiếp';

  @override
  String get sessionStop => 'Dừng';

  @override
  String get sessionSummaryQuestion => 'Câu hỏi cho buổi khám tới';

  @override
  String get sessionSaveToJournal => 'Lưu vào nhật ký';

  @override
  String get sessionSkipSaving => 'Không lưu';

  @override
  String get sessionPrivacyNote =>
      'Dù chọn cách nào, nhóm nghiên cứu cũng chỉ nhận thời gian buổi tập và mức tâm trạng bạn chọn, không bao giờ nhận những gì bạn viết.';

  @override
  String get sessionVideoError => 'Không mở được video của buổi tập';

  @override
  String sessionCaptionSemantics(String text) {
    return 'Phụ đề: $text';
  }

  @override
  String sessionPartSemantics(int number, int total, String title) {
    return 'Phần $number trên $total. $title';
  }

  @override
  String sessionPartLabel(int number, int total, String title) {
    return 'Phần $number/$total · $title';
  }

  @override
  String timeMinutes(int count) {
    return '$count phút';
  }

  @override
  String timeSeconds(int count) {
    return '$count giây';
  }

  @override
  String get sessionPause => 'Tạm dừng';

  @override
  String get sessionResume => 'Phát tiếp';

  @override
  String get sessionProgress => 'Tiến độ buổi tập';

  @override
  String sessionProgressValue(String position, String total) {
    return '$position trên $total';
  }

  @override
  String sessionBreathingGuide(String cue) {
    return 'Hướng dẫn thở: $cue';
  }

  @override
  String get journalErrorTitle => 'Không mở được nhật ký của bạn';

  @override
  String get journalEmptyTitle => 'Chưa có gì ở đây';

  @override
  String get journalEmptyBody =>
      'Hãy viết một dòng về hôm nay. Một câu là đủ — nhật ký để nhìn lại, không phải để viết cho hay.';

  @override
  String get journalEmptyAction => 'Viết dòng đầu tiên';

  @override
  String journalTodayCount(int count) {
    return 'Hôm nay bạn đã viết $count ghi chú.';
  }

  @override
  String get journalHowToday => 'Hôm nay bạn thấy thế nào?';

  @override
  String journalStreak(int count) {
    return '$count ngày liên tiếp';
  }

  @override
  String get greetingMorning => 'Chào buổi sáng';

  @override
  String get greetingAfternoon => 'Chào buổi chiều';

  @override
  String get greetingEvening => 'Chào buổi tối';

  @override
  String get dayToday => 'Hôm nay';

  @override
  String get dayYesterday => 'Hôm qua';

  @override
  String get insightsEmptyTitle => 'Chưa có gì để hiển thị';

  @override
  String get insightsEmptyBody =>
      'Hãy quay lại sau vài ngày — xu hướng chỉ có ý nghĩa khi đã có một ít dữ liệu.';

  @override
  String get insightsDays => 'ngày';

  @override
  String get insightsStreak => 'Chuỗi ngày hiện tại';

  @override
  String get insightsEntries => 'ghi chú';

  @override
  String get insightsWritten => 'Đã viết';

  @override
  String get insightsAverage => 'Trung bình 30 ngày';

  @override
  String get insightsTrendTitle => 'Tâm trạng trong 14 ngày';

  @override
  String get insightsTrendBody =>
      'Chạm vào biểu đồ để xem từng ngày. Ngày không có ghi chú được để trống.';

  @override
  String get insightsDistributionTitle => 'Bạn thường ở mức nào';

  @override
  String get insightsTagsTitle => 'Nhắc đến nhiều nhất';

  @override
  String get editorEditTitle => 'Sửa ghi chú';

  @override
  String get editorNewTitle => 'Hôm nay thế nào?';

  @override
  String get editorDelete => 'Xoá';

  @override
  String get editorNoteLabel => 'Ghi chú nhật ký';

  @override
  String get editorNoteHint => 'Viết vài dòng… (có thể để trống)';

  @override
  String get editorRelatedTo => 'Liên quan đến';

  @override
  String get editorSaveChanges => 'Lưu thay đổi';

  @override
  String editorSaveFailed(String error) {
    return 'Không lưu được: $error';
  }

  @override
  String get editorDiscardTitle => 'Bỏ những gì bạn đã viết?';

  @override
  String get editorDiscardBody => 'Những gì chưa lưu sẽ bị mất.';

  @override
  String get editorKeepWriting => 'Viết tiếp';

  @override
  String get editorDiscard => 'Bỏ';

  @override
  String get editorDeleteTitle => 'Xoá ghi chú này?';

  @override
  String get editorDeleteBody => 'Không thể hoàn tác.';

  @override
  String get editorChange => 'Đổi';

  @override
  String get entryEdit => 'Sửa';

  @override
  String get moodNotRecorded => 'Chưa ghi tâm trạng';

  @override
  String get entryMoodOnly =>
      'Hôm đó bạn chỉ ghi lại tâm trạng, không viết gì thêm.';

  @override
  String entryLastEdited(String date) {
    return 'Sửa lần cuối $date';
  }

  @override
  String get entryRemoteSession =>
      'Buổi tập đã hoàn thành trên một thiết bị khác.';

  @override
  String entryTags(String tags) {
    return 'Nhãn: $tags';
  }

  @override
  String get chartLabel => 'Biểu đồ xu hướng tâm trạng';

  @override
  String get chartHint =>
      'Dùng phím mũi tên trái, phải hoặc thao tác điều chỉnh để đọc từng ngày.';

  @override
  String get chartNoDays => 'Chưa có ngày nào được ghi';

  @override
  String chartDayValue(String date, String value) {
    return '$date, $value trên 5';
  }

  @override
  String distributionRow(String mood, int count, int percent) {
    return '$mood: $count lần, $percent phần trăm';
  }

  @override
  String get askTitle => 'Hỏi EmbraceAI';

  @override
  String get askIntroTitle => 'Hỏi về bài tập hoặc về app';

  @override
  String get askIntroBody =>
      'Câu trả lời chỉ lấy từ tài liệu của nghiên cứu. Mọi điều về sức khoẻ, thuốc men hay kết quả xét nghiệm, hãy hỏi nhóm chăm sóc của bạn. Vui lòng không ghi tên hay thông tin cá nhân khác.';

  @override
  String get askTryAsking => 'Thử hỏi';

  @override
  String get askExampleLength => 'Một buổi tập kéo dài bao lâu?';

  @override
  String get askExampleCaptions => 'Làm sao để bật phụ đề?';

  @override
  String get askExampleJournal => 'Ai có thể xem nhật ký của tôi?';

  @override
  String askYouAsked(String text) {
    return 'Bạn hỏi: $text';
  }

  @override
  String get askLooking => 'Đang tìm…';

  @override
  String get askMedicalTitle => 'Câu hỏi dành cho nhóm chăm sóc của bạn';

  @override
  String get askMedicalBody =>
      'Đây là câu hỏi dành cho bác sĩ hoặc nhóm chăm sóc của bạn. Bạn có thể lưu lại để hỏi trong buổi khám tới.';

  @override
  String get askOutOfScope =>
      'Tôi chỉ có thể giúp về các bài thư giãn và cách dùng app.';

  @override
  String get askNotFound =>
      'Hiện chưa có thông tin về điều này. Bạn có thể hỏi nhóm nghiên cứu.';

  @override
  String get askBusy => 'Hỏi EmbraceAI đang bận. Vui lòng thử lại sau ít phút.';

  @override
  String get askError => 'Đã có lỗi. Vui lòng thử lại.';

  @override
  String get askAlsoAsked =>
      'Bạn còn hỏi thêm một điều khác. Vui lòng hỏi riêng phần đó.';

  @override
  String get askSaved => 'Đã lưu vào nhật ký';

  @override
  String get askSaveForAppointment => 'Lưu cho buổi khám';

  @override
  String get askSources => 'Nguồn';

  @override
  String get askAiLabel =>
      'Do AI viết từ tài liệu nghiên cứu. Không phải lời khuyên y tế.';

  @override
  String get askEmergencyTitle =>
      'Nếu đây là tình huống khẩn cấp, hãy tìm trợ giúp ngay';

  @override
  String get askEmergencyBody =>
      'Hãy gọi ngay số cấp cứu nơi bạn đang ở. Nếu bạn thấy không khoẻ nhưng không khẩn cấp, hãy liên hệ nhóm chăm sóc của bạn. Dừng mọi bài tập đang làm.';

  @override
  String get askHint => 'Đặt câu hỏi';

  @override
  String get askSend => 'Gửi';

  @override
  String askAppointmentNote(String question) {
    return 'Câu hỏi cho buổi khám: $question';
  }

  @override
  String get authLinkExpired =>
      'Link đăng nhập này đã hết hạn hoặc đã được dùng. Hãy đăng nhập bằng Mã người tham gia và khoá truy cập, hoặc xin nhóm nghiên cứu một link mới.';

  @override
  String get authAccountNotActive =>
      'Tài khoản này chưa được kích hoạt cho EmbraceAI.';

  @override
  String authQrSignedOutOther(String participant) {
    return 'Mã QR này dành cho $participant. Một tài khoản khác đã lưu trên máy vừa được đăng xuất. Hãy quét lại mã QR để tiếp tục an toàn.';
  }

  @override
  String get authServiceUnreachable =>
      'Không kết nối được với dịch vụ đăng nhập.';

  @override
  String get authServiceUnreachableRetry =>
      'Không kết nối được với dịch vụ đăng nhập. Vui lòng thử lại.';

  @override
  String get authCheckDetails =>
      'Hãy kiểm tra lại Mã người tham gia và khoá truy cập, rồi thử lại.';

  @override
  String authPageForOther(String participant) {
    return 'Trang này được mở cho $participant. Hãy dùng đúng Mã người tham gia đó, hoặc mở lại địa chỉ chính của app.';
  }

  @override
  String get authInvalidDetails => 'Thông tin truy cập không đúng.';

  @override
  String get authParticipantInactive =>
      'Tài khoản người tham gia này đã hết hạn hoặc không còn hoạt động.';

  @override
  String authQrOtherNotOpened(String participant) {
    return 'Mã QR này dành cho $participant. Tài khoản kia không được mở.';
  }

  @override
  String get authNoStaffAccess =>
      'Tài khoản này không có quyền vào cổng nhân viên.';

  @override
  String get authTooManyAttempts =>
      'Thử quá nhiều lần. Vui lòng đợi một lát rồi thử lại.';

  @override
  String get authSuspended => 'Tài khoản này đã bị tạm khoá.';

  @override
  String get authNotVerified => 'Không xác minh được thông tin đăng nhập.';

  @override
  String get authThisParticipant => 'người tham gia này';

  @override
  String get loginIntro =>
      'Nhập thông tin truy cập mà nhóm nghiên cứu đã cung cấp cho bạn.';

  @override
  String get loginIdLabel => 'Mã người tham gia';

  @override
  String get loginIdMissing => 'Hãy nhập Mã người tham gia';

  @override
  String get loginKeyLabel => 'Khoá truy cập';

  @override
  String get loginShowKey => 'Hiện khoá truy cập';

  @override
  String get loginHideKey => 'Ẩn khoá truy cập';

  @override
  String get loginKeyMissing => 'Hãy nhập khoá truy cập';

  @override
  String get loginChecking => 'Đang kiểm tra...';

  @override
  String get loginPrivacy =>
      'EmbraceAI không hỏi tên, email cá nhân, số điện thoại hay số hồ sơ bệnh án của bạn.';

  @override
  String get gateStaffElsewhereTitle => 'Cổng nhân viên có địa chỉ riêng';

  @override
  String get gateStaffElsewhereBody =>
      'Tài khoản nhân viên đăng nhập tại địa chỉ dưới đây.';

  @override
  String get gateStaffPortalTitle => 'Đây là cổng nhân viên';

  @override
  String get gateParticipantsElsewhereBody =>
      'Người tham gia đăng nhập EmbraceAI tại địa chỉ dưới đây.';

  @override
  String get gateChecking => 'Đang kiểm tra quyền truy cập';

  @override
  String get studyLoadFailed =>
      'Không tải được thông tin nghiên cứu của bạn. Hãy kiểm tra kết nối rồi thử lại.';

  @override
  String get consentAppBar => 'Thông tin và đồng ý';

  @override
  String get consentTitle => 'Trước khi bạn tham gia';

  @override
  String get consentIntro =>
      'Vui lòng đọc kỹ thông tin này. Việc tham gia là hoàn toàn tự nguyện, và nếu bạn không tham gia thì việc chăm sóc sức khoẻ của bạn cũng không bị ảnh hưởng.';

  @override
  String get consentPurposeTitle => 'Mục đích';

  @override
  String get consentPurposeBody =>
      'Bản thử nghiệm này cung cấp một bài thư giãn có AI hướng dẫn và hỏi về trải nghiệm của bạn, để nhóm nghiên cứu đánh giá và cải thiện nó.';

  @override
  String get consentChoiceTitle => 'Quyền lựa chọn của bạn';

  @override
  String get consentChoiceBody =>
      'Bạn có thể dừng buổi tập bất cứ lúc nào, bỏ trống các câu hỏi không bắt buộc, hoặc liên hệ thành viên nhóm nghiên cứu đã cấp quyền truy cập cho bạn nếu muốn rút khỏi nghiên cứu.';

  @override
  String get consentSafetyTitle => 'An toàn y tế';

  @override
  String get consentDataTitle => 'Thông tin được thu thập';

  @override
  String get consentDataBody =>
      'Câu trả lời của bạn được gắn với Mã người tham gia do nghiên cứu cấp. App thu thập bảng thông tin nhân khẩu và sức khoẻ đã được phê duyệt, hoạt động trong các buổi tập, mức tâm trạng và các bảng câu hỏi của nghiên cứu. App không hỏi tên, email cá nhân, số điện thoại hay số hồ sơ bệnh án của bạn.';

  @override
  String get consentConfirmEach => 'Vui lòng xác nhận từng mục';

  @override
  String get consentRead => 'Tôi đã đọc và hiểu thông tin ở trên.';

  @override
  String get consentVoluntary =>
      'Tôi hiểu rằng việc tham gia là tự nguyện và tôi có thể dừng bất cứ lúc nào.';

  @override
  String get consentNotTreatment =>
      'Tôi hiểu rằng bài thư giãn này không phải là điều trị y tế.';

  @override
  String get consentDataUse =>
      'Tôi đồng ý để nhóm nghiên cứu thu thập và sử dụng các thông tin nêu trên cho nghiên cứu này.';

  @override
  String get consentAccept => 'Tôi đồng ý và tiếp tục';

  @override
  String get consentExit => 'Thoát mà không đồng ý';

  @override
  String consentVersion(String version) {
    return 'Phiên bản bản đồng ý: $version';
  }

  @override
  String get consentSaving => 'Đang lưu sự đồng ý của bạn...';

  @override
  String get consentSaveFailed =>
      'Không ghi nhận được sự đồng ý của bạn. Vui lòng thử lại.';

  @override
  String get consentStudyAccess => 'Quyền truy cập nghiên cứu';

  @override
  String get consentWithdrawnTitle => 'Bạn đã rút lại sự đồng ý';

  @override
  String get consentWithdrawnBody =>
      'Không thể dùng tài khoản nghiên cứu này. Nếu bạn cho rằng có nhầm lẫn, hãy liên hệ thành viên nhóm nghiên cứu đã cấp quyền truy cập cho bạn.';

  @override
  String get demoAppBar => 'Về bạn';

  @override
  String get demoQuestionAge => 'Tuổi (tính theo năm)';

  @override
  String get demoQuestionGender => 'Giới tính';

  @override
  String get demoQuestionEthnicity => 'Nguồn gốc dân tộc';

  @override
  String get demoQuestionCountry => 'Quốc gia nơi sinh';

  @override
  String get demoQuestionRelationship => 'Tình trạng hôn nhân';

  @override
  String get demoQuestionDiagnosis => 'Chẩn đoán bệnh tim mạch';

  @override
  String get demoQuestionComorbidities => 'Các bệnh lý khác / bệnh đi kèm';

  @override
  String get genderFemale => 'Nữ';

  @override
  String get genderMale => 'Nam';

  @override
  String get optionPreferNotToSay => 'Không muốn trả lời';

  @override
  String get ethnicityAsian => 'Người châu Á';

  @override
  String get ethnicityIndigenous => 'Người bản địa';

  @override
  String get ethnicityLatinAmerican => 'Người Mỹ Latinh';

  @override
  String get ethnicityMiddleEastern => 'Người Trung Đông';

  @override
  String get ethnicityWhite => 'Người da trắng';

  @override
  String get ethnicityMixed => 'Lai / nhiều nguồn gốc';

  @override
  String get ethnicityOther => 'Khác';

  @override
  String get relationshipSingle => 'Độc thân, kể cả ly thân, ly hôn hoặc goá';

  @override
  String get relationshipPartnered =>
      'Đang có bạn đời hoặc người yêu, kể cả đã kết hôn';

  @override
  String get demoReviewAnswers => 'Xem lại câu trả lời';

  @override
  String demoQuestionOf(int number, int total) {
    return 'Câu $number/$total';
  }

  @override
  String get demoIntroTitle => 'Thông tin người tham gia';

  @override
  String get demoIntroBody =>
      'Vui lòng điền một lần trước khi bắt đầu chương trình. Hồ sơ của bạn chỉ dùng Mã người tham gia do nghiên cứu cấp.';

  @override
  String get demoHealthInfo => 'Thông tin sức khoẻ';

  @override
  String get demoPersonalInfo => 'Thông tin cá nhân';

  @override
  String get demoPleaseSpecify => 'Vui lòng ghi rõ';

  @override
  String get demoOptional => 'Không bắt buộc';

  @override
  String get demoOptionalNote => 'Câu này không bắt buộc.';

  @override
  String get demoCheckTitle => 'Kiểm tra câu trả lời';

  @override
  String get demoCheckBody => 'Bạn có thể sửa bất kỳ câu nào trước khi lưu.';

  @override
  String get demoNotAnswered => 'Chưa trả lời';

  @override
  String demoOtherValue(String value) {
    return 'Khác: $value';
  }

  @override
  String get demoEnterAge => 'Hãy nhập tuổi.';

  @override
  String get demoValidAge => 'Hãy nhập một tuổi hợp lệ.';

  @override
  String get demoSelectOption => 'Hãy chọn một mục.';

  @override
  String get demoDescribeBackground => 'Vui lòng mô tả nguồn gốc của bạn.';

  @override
  String get demoSelectCountry => 'Hãy chọn một quốc gia.';

  @override
  String get demoRequired => 'Câu này cần được trả lời.';

  @override
  String get demoSaveFailed =>
      'Không lưu được thông tin của bạn. Vui lòng thử lại.';

  @override
  String get demoCountryHint => 'Tìm hoặc chọn quốc gia';

  @override
  String changeSemantics(String label) {
    return 'Đổi $label';
  }

  @override
  String get finalAppBar => 'Bảng câu hỏi cuối';

  @override
  String get finalSubmit => 'Gửi';

  @override
  String get finalDoLater => 'Để sau';

  @override
  String get finalSectionWellbeing => 'Sức khoẻ cảm xúc';

  @override
  String get finalSectionExperience => 'Trải nghiệm của bạn';

  @override
  String get finalSectionOwnWords => 'Theo lời của bạn';

  @override
  String get gadStem =>
      'Trong 2 tuần qua, bạn có thường bị phiền bởi những vấn đề sau không?';

  @override
  String get gad1 => 'Cảm thấy bồn chồn, lo âu hoặc căng thẳng';

  @override
  String get gad2 => 'Khó kiểm soát sự lo lắng';

  @override
  String get gad3 => 'Lo lắng quá nhiều về nhiều chuyện khác nhau';

  @override
  String get gad4 => 'Khó thư giãn';

  @override
  String get gad5 => 'Bứt rứt / khó ngồi yên';

  @override
  String get gad6 => 'Dễ bực mình hoặc cáu gắt';

  @override
  String get gad7 => 'Cảm thấy sợ như thể có điều gì tồi tệ sắp xảy ra';

  @override
  String get gadNotAtAll => 'Không ngày nào';

  @override
  String get gadSeveralDays => 'Vài ngày';

  @override
  String get gadMoreThanHalf => 'Hơn một nửa số ngày';

  @override
  String get gadNearlyEveryDay => 'Gần như mỗi ngày';

  @override
  String get wellbeingQuestion =>
      'Bạn đánh giá sức khoẻ cảm xúc chung của mình lúc này thế nào?';

  @override
  String get wellbeingVeryPoor => 'Rất kém';

  @override
  String get wellbeingPoor => 'Kém';

  @override
  String get wellbeingFair => 'Trung bình';

  @override
  String get wellbeingGood => 'Tốt';

  @override
  String get wellbeingVeryGood => 'Rất tốt';

  @override
  String get premStem =>
      'Vui lòng cho biết bạn đồng ý hay không đồng ý ở mức nào.';

  @override
  String get prem1 => 'Hướng dẫn dễ hiểu.';

  @override
  String get prem2 => 'Tôi thấy thoải mái khi dùng hệ thống.';

  @override
  String get prem3 => 'Trải nghiệm này giúp tôi bình tâm và thư giãn.';

  @override
  String get prem4 => 'Hệ thống dễ thao tác.';

  @override
  String get prem5 => 'Tôi thấy an toàn trong suốt trải nghiệm.';

  @override
  String get prem6 => 'Trải nghiệm này có ích cho sức khoẻ tinh thần của tôi.';

  @override
  String get prem7 => 'Tôi sẵn lòng dùng lại hệ thống này.';

  @override
  String get prem8 => 'Nhìn chung, tôi hài lòng với trải nghiệm này.';

  @override
  String get premStronglyDisagree => 'Hoàn toàn không đồng ý';

  @override
  String get premDisagree => 'Không đồng ý';

  @override
  String get premNeutral => 'Trung lập';

  @override
  String get premAgree => 'Đồng ý';

  @override
  String get premStronglyAgree => 'Hoàn toàn đồng ý';

  @override
  String get open1 => 'Bạn thích điều gì nhất ở trải nghiệm này?';

  @override
  String get open2 =>
      'Nếu có, điều gì khiến bạn thấy khó khăn hoặc không thoải mái?';

  @override
  String get open3 => 'Có thể cải thiện hệ thống như thế nào?';

  @override
  String get open4 =>
      'Bạn có dùng lại hệ thống này không? Vui lòng giải thích vì sao có hoặc không.';

  @override
  String get finalClearAnswer => 'Xoá câu trả lời';

  @override
  String get finalOpenIntro =>
      'Bạn có thể để trống. Vui lòng không ghi tên hay thông tin liên lạc.';

  @override
  String get finalOpenHint => 'Câu trả lời của bạn (không bắt buộc)';

  @override
  String get finalReviewTitle => 'Xem lại và gửi';

  @override
  String get finalReviewBody =>
      'Câu trả lời của bạn chỉ được gắn với Mã người tham gia do nghiên cứu cấp. Bạn có thể quay lại sửa trước khi gửi.';

  @override
  String finalReviewQuestions(int first, int last) {
    return 'Câu $first–$last';
  }

  @override
  String finalAnsweredOf(int count, int total) {
    return 'Đã trả lời $count/$total';
  }

  @override
  String get finalSaveFailed =>
      'Không lưu được câu trả lời của bạn. Vui lòng thử lại.';

  @override
  String get dictationStart => 'Nói thay vì gõ';

  @override
  String get dictationStop => 'Dừng và chuyển thành chữ';

  @override
  String dictationRecording(int seconds) {
    return 'Đang ghi âm, còn $seconds giây';
  }

  @override
  String get dictationWorking => 'Đang chuyển lời nói thành chữ…';

  @override
  String get dictationNotHeard =>
      'Chưa nghe được gì. Bạn thử lại, nói gần micro hơn một chút nhé.';

  @override
  String get dictationBusy =>
      'Tính năng nói thay vì gõ đang bận. Bạn thử lại sau ít phút, hoặc gõ phím nhé.';

  @override
  String get dictationFailed =>
      'Lần này chưa chuyển được lời nói thành chữ. Bạn gõ phím giúp nhé.';

  @override
  String get dictationNoMic =>
      'Không dùng được micro. Bạn cho phép trình duyệt dùng micro rồi thử lại nhé.';

  @override
  String get prepConcernTitle =>
      'Có điều gì bạn muốn nhóm chăm sóc sức khoẻ hiểu rõ hoặc trao đổi trong buổi khám tới không?';

  @override
  String get prepConcernSubtitle =>
      'Hãy kể bằng lời của bạn: điều bạn nhận thấy, hoặc điều bạn muốn hỏi.';

  @override
  String get prepConcernLabel => 'Điều bạn lo, triệu chứng hoặc câu hỏi';

  @override
  String get prepConcernHint =>
      'Ví dụ: tôi thấy chóng mặt sau khi uống thuốc buổi sáng.';

  @override
  String get prepTopicsTitle => 'Bạn muốn hỏi điều gì nhất?';

  @override
  String get prepTopicsSubtitle => 'Chọn một hoặc nhiều mục.';

  @override
  String get prepTopicWhy => 'Vì sao điều này có thể xảy ra';

  @override
  String get prepTopicMonitor => 'Tôi nên theo dõi điều gì';

  @override
  String get prepTopicNextTime => 'Nên làm gì nếu nó xảy ra lại';

  @override
  String get prepTopicOther => 'Điều khác';

  @override
  String get prepWorking => 'Đang sắp xếp câu hỏi của bạn…';

  @override
  String get prepResultTitle => 'Cách hỏi rõ ràng hơn';

  @override
  String get prepResultSubtitle =>
      'Câu này chỉ dùng những gì bạn đã viết. Bạn có thể sửa trước khi lưu.';

  @override
  String get prepBusyTitle => 'Lúc này chưa viết lại được';

  @override
  String get prepBusyBody =>
      'Bạn có thể lưu bằng lời của mình, hoặc thử lại sau một phút.';

  @override
  String get prepNotAdvice =>
      'Phần này chỉ giúp bạn đặt câu hỏi, không phải lời khuyên y tế.';

  @override
  String get prepSave => 'Lưu câu hỏi';

  @override
  String get prepEdit => 'Sửa';

  @override
  String get prepEditDone => 'Sửa xong';

  @override
  String get prepEditLabel => 'Câu hỏi của bạn';

  @override
  String get prepAnotherWording => 'Thử cách viết khác';

  @override
  String get prepFull =>
      'Bạn đã lưu đủ 3 câu hỏi. Hãy xoá bớt một câu trong mục Câu hỏi cho buổi khám để thêm câu này.';

  @override
  String get prepEmergencyTitle => 'Hãy tìm trợ giúp trước';

  @override
  String get prepEmergencyAfter =>
      'Nếu chuyện đó đã xảy ra trước đây và đã qua, hãy liên hệ nhóm chăm sóc của bạn sớm, đừng đợi tới buổi khám.';

  @override
  String get prepSavedTitle => 'Đã lưu cho buổi khám tới';

  @override
  String prepSavedBody(int count, int max) {
    return 'Bạn có $count trên $max câu hỏi. Bạn có thể xem và sắp xếp lại trong mục Câu hỏi cho buổi khám.';
  }

  @override
  String get appointmentListTitle => 'Câu hỏi cho buổi khám';

  @override
  String get appointmentListIntro =>
      'Mang những câu này tới buổi khám tới. Câu hỏi 1 là câu bạn sẽ hỏi trước. Dùng nút Đưa lên hoặc Đưa xuống để đổi thứ tự.';

  @override
  String get appointmentListEmpty => 'Chưa có câu hỏi nào.';

  @override
  String get appointmentListFull =>
      'Bạn giữ được tối đa 3 câu hỏi. Xoá bớt một câu để thêm câu khác.';

  @override
  String get appointmentAdd => 'Thêm câu hỏi';

  @override
  String get appointmentMoveUp => 'Đưa lên';

  @override
  String get appointmentMoveDown => 'Đưa xuống';

  @override
  String get appointmentDelete => 'Xoá';

  @override
  String get appointmentDeleted => 'Đã xoá câu hỏi';

  @override
  String appointmentNumber(int number) {
    return 'Câu hỏi $number';
  }

  @override
  String get appointmentLoadFailed =>
      'Chưa tải được câu hỏi của bạn. Bạn kiểm tra kết nối mạng rồi thử lại nhé.';

  @override
  String get appointmentSaveFailed =>
      'Chưa lưu được. Bạn kiểm tra kết nối mạng rồi thử lại nhé.';

  @override
  String get appointmentEntry => 'Chuẩn bị câu hỏi cho buổi khám';

  @override
  String get appointmentEntryBody =>
      'Biến những điều bạn nhận thấy thành câu hỏi rõ ràng cho nhóm chăm sóc.';

  @override
  String get prepFullTitle => 'Bạn đã có 3 câu hỏi sẵn sàng cho buổi khám tới';

  @override
  String get prepFullBody =>
      'Hãy giữ chúng cho buổi khám, hoặc thay một câu bằng câu hỏi mới.';

  @override
  String get prepReplace => 'Thay câu này';

  @override
  String prepReplacing(String question) {
    return 'Câu hỏi mới sẽ thay cho: $question';
  }

  @override
  String appointmentMoved(int number) {
    return 'Đã chuyển thành câu hỏi $number';
  }

  @override
  String prepStep(int step, int total) {
    return 'Bước $step/$total';
  }

  @override
  String get prepWorkingBody => 'Thường chỉ mất vài giây.';

  @override
  String get appointmentRemoveTitle => 'Xoá câu hỏi này?';

  @override
  String get appointmentEmptyBody =>
      'Ghi lại điều bạn muốn hỏi nhóm chăm sóc, và nhận trợ giúp để diễn đạt cho rõ ràng.';

  @override
  String appointmentCount(int count, int max) {
    return '$count trên $max câu hỏi';
  }

  @override
  String get prepErrorBody =>
      'Bạn có thể lưu bằng lời của mình, sửa lại trước, hoặc thử lại.';
}
