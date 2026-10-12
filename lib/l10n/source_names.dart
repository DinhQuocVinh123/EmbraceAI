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
};

/// Tên tài liệu nguồn theo mã ngôn ngữ đang dùng (`AppLocalizations.localeName`).
String sourceName(String name, String languageCode) => languageCode == 'vi'
    ? vietnameseSourceNames[name] ?? name
    : name;
