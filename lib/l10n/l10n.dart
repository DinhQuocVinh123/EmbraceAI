import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Chữ hiển thị theo ngôn ngữ đang chọn: `context.l10n.welcomeTitle`.
///
/// Màn hình dựng ngoài app (ví dụ trong test, với một MaterialApp trơn) không
/// có bản dịch nào được nạp; khi đó dùng tiếng Anh.
extension AppL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this) ?? english;
}

/// Bản tiếng Anh, cho chỗ không có [BuildContext] hoặc luôn hiện tiếng Anh
/// (cổng nhân viên).
final AppLocalizations english = lookupAppLocalizations(const Locale('en'));
