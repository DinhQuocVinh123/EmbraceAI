/// Hai bản web build từ cùng một code: app cho người tham gia và cổng cho
/// nhân viên, mỗi bản ở một địa chỉ riêng.
///
/// Tách địa chỉ để mỗi bên có kho phiên đăng nhập riêng của trình duyệt:
/// nhân viên mở thử link QR của người tham gia không bị đẩy khỏi cổng staff.
/// Chọn bản khi build bằng `--dart-define=APP_SURFACE=staff`; mặc định là app
/// người tham gia.
enum AppSurface {
  participant,
  staff;

  static const current = String.fromEnvironment('APP_SURFACE') == 'staff'
      ? AppSurface.staff
      : AppSurface.participant;

  static const participantAppUrl = String.fromEnvironment(
    'PARTICIPANT_APP_URL',
    defaultValue: 'https://embrace-ai-prototype-2026.web.app',
  );

  static const staffPortalUrl = String.fromEnvironment(
    'STAFF_PORTAL_URL',
    defaultValue: 'https://embrace-ai-staff.web.app',
  );
}
