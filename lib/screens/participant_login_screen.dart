import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../state/auth_store.dart';
import '../widgets/language_picker.dart';

class ParticipantLoginScreen extends StatefulWidget {
  const ParticipantLoginScreen({super.key});

  @override
  State<ParticipantLoginScreen> createState() => _ParticipantLoginScreenState();
}

class _ParticipantLoginScreenState extends State<ParticipantLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _keyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void dispose() {
    _codeController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Chọn ngôn ngữ trước khi đăng nhập; nhãn luôn ghi cả hai
                    // thứ tiếng để ai cũng tìm ra.
                    const Align(
                      alignment: Alignment.centerRight,
                      child: LanguageButton(showLabel: true),
                    ),
                    Icon(
                      Icons.self_improvement,
                      size: 54,
                      color: theme.colorScheme.primary,
                      semanticLabel: 'EmbraceAI',
                    ),
                    Gap.m,
                    Text(
                      'EmbraceAI',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap.s,
                    Text(
                      l10n.loginIntro,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    Gap.xl,
                    TextFormField(
                      controller: _codeController,
                      enabled: !auth.isBusy,
                      textCapitalization: TextCapitalization.characters,
                      autofillHints: const [AutofillHints.username],
                      decoration: InputDecoration(
                        labelText: l10n.loginIdLabel,
                        hintText: 'EA-XXXX-XXXX',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? l10n.loginIdMissing
                          : null,
                    ),
                    Gap.m,
                    TextFormField(
                      controller: _keyController,
                      enabled: !auth.isBusy,
                      obscureText: _obscureKey,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: l10n.loginKeyLabel,
                        prefixIcon: const Icon(Icons.key_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscureKey
                              ? l10n.loginShowKey
                              : l10n.loginHideKey,
                          onPressed: () =>
                              setState(() => _obscureKey = !_obscureKey),
                          icon: Icon(
                            _obscureKey
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? l10n.loginKeyMissing
                          : null,
                      onFieldSubmitted: (_) => _submit(auth),
                    ),
                    if (auth.error case final error?) ...[
                      Gap.m,
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          authErrorText(l10n, error),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                    Gap.l,
                    FilledButton.icon(
                      onPressed: auth.isBusy ? null : () => _submit(auth),
                      icon: auth.isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        auth.isBusy ? l10n.loginChecking : l10n.commonContinue,
                      ),
                    ),
                    Gap.m,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        Gap.s,
                        Expanded(
                          child: Text(
                            l10n.loginPrivacy,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _submit(AuthStore auth) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await auth.signInParticipant(
      participantCode: _codeController.text,
      accessKey: _keyController.text,
    );
  }
}
