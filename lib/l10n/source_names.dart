/// Tên tiếng Việt của tài liệu nguồn mà Ask EmbraceAI dựa vào.
///
/// Máy chủ gửi tên tiếng Anh như trong tài liệu gốc (`tools/ai-lab/content`).
/// Tên chưa có ở đây thì hiện nguyên tiếng Anh; test kiểm mọi mục trên kệ hiện
/// nay đều có tên tiếng Việt.
const vietnameseSourceNames = {
  'EmbraceAI Prototype User Guide (participant sections)':
      'Hướng dẫn sử dụng EmbraceAI (phần người tham gia)',
  'Participant app: signing in': 'App người tham gia: đăng nhập',
  'Participant app: first visit': 'App người tham gia: lần đầu sử dụng',
  'Participant app: a guided session': 'App người tham gia: một buổi tập',
  'Participant app: journal and insights':
      'App người tham gia: nhật ký và thống kê',
  'Participant app: final questionnaire':
      'App người tham gia: bảng câu hỏi cuối',
  'Privacy and data': 'Quyền riêng tư và dữ liệu',
  'Troubleshooting': 'Xử lý sự cố',
  // Ba tài liệu sức khoẻ (biên bản họp, mục 3), bản nháp chờ duyệt.
  'Living with a heart condition: symptoms and when to get help':
      'Sống với bệnh tim: triệu chứng và khi nào cần trợ giúp',
  'About this health information': 'Về thông tin sức khoẻ này',
  'Emergency signs: get help straight away':
      'Dấu hiệu cấp cứu: tìm trợ giúp ngay',
  'Shortness of breath': 'Khó thở',
  'Swelling in the ankles, legs or tummy': 'Phù ở mắt cá, chân hoặc bụng',
  'A racing, fluttering or skipping heartbeat':
      'Tim đập nhanh, rung hoặc hẫng nhịp',
  'Dizziness or light-headedness': 'Chóng mặt hoặc choáng váng',
  'Tiredness and low energy': 'Mệt mỏi và thiếu năng lượng',
  'Side effects of medicines': 'Tác dụng phụ của thuốc',
  'Taking medicines well': 'Uống thuốc đúng cách',
  'Keeping notes for your appointment': 'Ghi chép cho buổi khám',
  'When to contact your care team': 'Khi nào cần liên hệ nhóm chăm sóc',
  'Feelings and emotional wellbeing': 'Cảm xúc và sức khoẻ tinh thần',
  'About this wellbeing information': 'Về thông tin sức khoẻ tinh thần này',
  'Common feelings with a heart condition':
      'Những cảm xúc thường gặp khi có bệnh tim',
  'Stress': 'Căng thẳng',
  'Worry and anxiety': 'Lo lắng và lo âu',
  'Low mood': 'Tâm trạng buồn chán',
  'Sleep': 'Giấc ngủ',
  'Feeling alone': 'Cảm thấy cô đơn',
  'Practices in the EmbraceAI app': 'Các bài tập trong app EmbraceAI',
  'When to get more support': 'Khi nào cần thêm hỗ trợ',
  'Healthy living and self-care': 'Lối sống lành mạnh và tự chăm sóc',
  'About this healthy living information':
      'Về thông tin lối sống lành mạnh này',
  'Eating for heart health': 'Ăn uống tốt cho tim',
  'Salt': 'Muối',
  'Fluids': 'Lượng nước uống',
  'Physical activity': 'Vận động thể chất',
  'Smoking and alcohol': 'Thuốc lá và rượu bia',
  'Checking your health at home': 'Tự theo dõi sức khoẻ tại nhà',
  'Rest and pacing': 'Nghỉ ngơi và phân bổ sức',
};

/// Tên tài liệu nguồn theo mã ngôn ngữ đang dùng (`AppLocalizations.localeName`).
String sourceName(String name, String languageCode) => languageCode == 'vi'
    ? vietnameseSourceNames[name] ?? name
    : name;
