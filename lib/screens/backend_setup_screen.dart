import 'package:flutter/material.dart';

import '../core/theme.dart';

class BackendSetupScreen extends StatelessWidget {
  const BackendSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.settings_suggest_outlined,
                    size: 52,
                    color: theme.colorScheme.primary,
                  ),
                  Gap.m,
                  Text(
                    'Backend setup required',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Gap.s,
                  Text(
                    'This build needs its Supabase project URL and publishable '
                    'key. No patient information is stored in the app bundle.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
