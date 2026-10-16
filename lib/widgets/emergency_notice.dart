import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Thẻ hướng dẫn khi lời người tham gia có dấu hiệu khẩn cấp (danh sách từ
/// trong supabase/functions/_shared/emergency.ts). Chữ cố định, không có chữ
/// nào do AI viết. Dùng ở Ask EmbraceAI và thẻ chuẩn bị câu hỏi cho buổi khám.
class EmergencyNotice extends StatelessWidget {
  const EmergencyNotice({super.key, this.extra});

  /// Một câu thêm sau phần hướng dẫn chung, tuỳ nơi dùng.
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: AppRadius.lg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.emergency_outlined, color: theme.colorScheme.error),
            Gap.s,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.askEmergencyTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap.xs,
                  Text(
                    context.l10n.askEmergencyBody,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  if (extra case final extra?) ...[
                    Gap.s,
                    Text(
                      extra,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
