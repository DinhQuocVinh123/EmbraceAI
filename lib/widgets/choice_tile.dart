import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Một lựa chọn trong câu hỏi trắc nghiệm.
///
/// Ô lớn, đủ chỗ cho chữ to và dễ bấm; mọi lựa chọn nằm sẵn trên màn hình
/// thay vì giấu trong menu thả xuống. Trạng thái đã chọn hiện bằng nút tròn,
/// viền và chữ đậm, không chỉ bằng màu nền.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.score,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Điểm của lựa chọn trên thang đo, hiện trước nhãn (ví dụ 0–3 của GAD-7).
  final int? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: score == null ? label : '$score, $label',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.4)
              : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.md,
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.md,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    Gap.m,
                    if (score != null) ...[
                      Text(
                        '$score',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Gap.s,
                    ],
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
