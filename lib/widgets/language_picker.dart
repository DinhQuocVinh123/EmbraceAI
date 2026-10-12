import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../state/settings_store.dart';
import 'choice_tile.dart';

/// Chọn ngôn ngữ: theo điện thoại, English hoặc Tiếng Việt.
///
/// Tên mỗi ngôn ngữ luôn viết bằng chính ngôn ngữ đó, để người không đọc được
/// ngôn ngữ đang hiện vẫn nhận ra lựa chọn của mình. Đổi xong có hiệu lực ngay.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  static const _names = {
    AppLanguage.english: 'English',
    AppLanguage.vietnamese: 'Tiếng Việt',
  };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final language in AppLanguage.values) ...[
          ChoiceTile(
            label: _names[language] ?? l10n.languagePhone,
            selected: settings.language == language,
            onTap: () => settings.setLanguage(language),
          ),
          if (language != AppLanguage.values.last) Gap.s,
        ],
      ],
    );
  }
}

/// Nút đổi ngôn ngữ: mở bảng chọn ở cạnh dưới màn hình. Biểu tượng dịch thuật
/// nhận ra được dù không đọc được chữ; [showLabel] thêm nhãn ghi cả hai thứ
/// tiếng, dùng ở màn hình đăng nhập.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key, this.showLabel = false});

  final bool showLabel;

  static Future<void> showSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      sheetAnimationStyle: AppMotion.style(context),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    context.l10n.languageTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Gap.m,
                const LanguagePicker(),
                Gap.m,
                Text(
                  context.l10n.languageVoiceNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showLabel) {
      return TextButton.icon(
        onPressed: () => showSheet(context),
        icon: const Icon(Icons.translate),
        label: const Text('English · Tiếng Việt'),
      );
    }
    return IconButton(
      tooltip: context.l10n.languageButtonTooltip,
      onPressed: () => showSheet(context),
      icon: const Icon(Icons.translate),
    );
  }
}
