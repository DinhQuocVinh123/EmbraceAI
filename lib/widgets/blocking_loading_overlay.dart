import 'package:flutter/material.dart';

class BlockingLoadingOverlay extends StatelessWidget {
  const BlockingLoadingOverlay({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        ModalBarrier(
          dismissible: false,
          color: scheme.scrim.withValues(alpha: 0.32),
        ),
        Center(
          child: Semantics(
            liveRegion: true,
            label: message,
            child: Material(
              color: scheme.surface,
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
