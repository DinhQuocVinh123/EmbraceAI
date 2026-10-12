enum ConsentStatus { pending, accepted, withdrawn }

const studyConsentVersion = '2026-09-28-prototype-v1';

/// Phiên bản ghi vào hồ sơ đồng ý, kèm ngôn ngữ của bản người tham gia đã đọc.
/// Bản tiếng Việt là bản dịch nháp: khi nhóm nghiên cứu duyệt xong thì đổi
/// hậu tố `-vi-draft` thành `-vi`.
String consentVersionFor(String languageCode) => languageCode == 'vi'
    ? '$studyConsentVersion-vi-draft'
    : studyConsentVersion;
