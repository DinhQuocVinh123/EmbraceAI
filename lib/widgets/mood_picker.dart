import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/mood.dart';

/// Hàng năm khuôn mặt để chọn tâm trạng.
class MoodPicker extends StatelessWidget {
  const MoodPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Mood selected;
  final ValueChanged<Mood> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final mood in Mood.values)
          Expanded(
            child: _MoodOption(
              mood: mood,
              isSelected: mood == selected,
              onTap: () => onChanged(mood),
              textStyle: theme.textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({
    required this.mood,
    required this.isSelected,
    required this.onTap,
    required this.textStyle,
  });

  final Mood mood;
  final bool isSelected;
  final VoidCallback onTap;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: isSelected,
      button: true,
      label: mood.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? mood.color.withValues(alpha: 0.28)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: Border.all(
                    color: isSelected ? mood.color : Colors.transparent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  mood.emoji,
                  style: TextStyle(fontSize: isSelected ? 26 : 22),
                ),
              ),
              Gap.xs,
              Text(
                mood.label,
                textAlign: TextAlign.center,
                style: textStyle?.copyWith(
                  color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
