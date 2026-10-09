import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Thanh nút cố định ở đáy các bảng hỏi từng bước: Quay lại và Tiếp.
///
/// Nút luôn nằm trong tầm nhìn nên người dùng không phải cuộn tìm. Ở cỡ chữ
/// lớn, hai nút xếp chồng để nhãn không bị cắt.
class StepActions extends StatelessWidget {
  const StepActions({
    super.key,
    required this.nextLabel,
    required this.nextIcon,
    required this.onNext,
    this.backLabel,
    this.onBack,
    this.busy = false,
  });

  final String nextLabel;
  final IconData nextIcon;
  final VoidCallback? onNext;

  /// Không có nhãn thì chỉ hiện nút Tiếp.
  final String? backLabel;
  final VoidCallback? onBack;

  /// Đang lưu: nút Tiếp hiện vòng quay, cả hai nút tạm khoá.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final next = FilledButton.icon(
      onPressed: busy ? null : onNext,
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(nextIcon),
      label: Text(nextLabel),
    );
    final label = backLabel;
    final back = label == null
        ? null
        : OutlinedButton(onPressed: busy ? null : onBack, child: Text(label));
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: back == null
              ? SizedBox(width: double.infinity, child: next)
              : largeText
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: double.infinity, child: next),
                    Gap.s,
                    SizedBox(width: double.infinity, child: back),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: back),
                    Gap.m,
                    Expanded(child: next),
                  ],
                ),
        ),
      ),
    );
  }
}
