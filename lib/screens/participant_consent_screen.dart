import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../models/consent.dart';
import '../services/study_assessment_service.dart';
import '../widgets/blocking_loading_overlay.dart';
import '../widgets/language_picker.dart';

class ParticipantConsentScreen extends StatefulWidget {
  const ParticipantConsentScreen({
    super.key,
    required this.service,
    required this.onAccepted,
    required this.onSignOut,
  });

  final StudyAssessmentService service;
  final Future<void> Function() onAccepted;
  final Future<void> Function() onSignOut;

  @override
  State<ParticipantConsentScreen> createState() =>
      _ParticipantConsentScreenState();
}

class _ParticipantConsentScreenState extends State<ParticipantConsentScreen> {
  final _checks = List<bool>.filled(4, false);
  bool _saving = false;

  bool get _canConsent => _checks.every((checked) => checked) && !_saving;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final version = consentVersionFor(l10n.localeName);
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(l10n.consentAppBar),
            actions: [
              const LanguageButton(),
              IconButton(
                tooltip: l10n.homeSignOut,
                onPressed: _saving ? null : widget.onSignOut,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 44,
                      color: scheme.primary,
                    ),
                    Gap.m,
                    Text(
                      l10n.consentTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Gap.s,
                    Text(
                      l10n.consentIntro,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Gap.xl,
                    _InformationSection(
                      icon: Icons.science_outlined,
                      title: l10n.consentPurposeTitle,
                      body: l10n.consentPurposeBody,
                    ),
                    _InformationSection(
                      icon: Icons.volunteer_activism_outlined,
                      title: l10n.consentChoiceTitle,
                      body: l10n.consentChoiceBody,
                    ),
                    _InformationSection(
                      icon: Icons.medical_information_outlined,
                      title: l10n.consentSafetyTitle,
                      body: l10n.disclaimerBody,
                    ),
                    _InformationSection(
                      icon: Icons.shield_outlined,
                      title: l10n.consentDataTitle,
                      body: l10n.consentDataBody,
                    ),
                    Gap.l,
                    Text(
                      l10n.consentConfirmEach,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap.s,
                    _ConsentCheck(
                      value: _checks[0],
                      text: l10n.consentRead,
                      onChanged: (value) => _setCheck(0, value),
                    ),
                    _ConsentCheck(
                      value: _checks[1],
                      text: l10n.consentVoluntary,
                      onChanged: (value) => _setCheck(1, value),
                    ),
                    _ConsentCheck(
                      value: _checks[2],
                      text: l10n.consentNotTreatment,
                      onChanged: (value) => _setCheck(2, value),
                    ),
                    _ConsentCheck(
                      value: _checks[3],
                      text: l10n.consentDataUse,
                      onChanged: (value) => _setCheck(3, value),
                    ),
                    Gap.l,
                    FilledButton.icon(
                      onPressed: _canConsent ? _accept : null,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(l10n.consentAccept),
                    ),
                    Gap.s,
                    TextButton(
                      onPressed: _saving ? null : widget.onSignOut,
                      child: Text(l10n.consentExit),
                    ),
                    Gap.m,
                    Text(
                      l10n.consentVersion(version),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_saving)
          BlockingLoadingOverlay(message: l10n.consentSaving),
      ],
    );
  }

  void _setCheck(int index, bool? value) {
    setState(() => _checks[index] = value ?? false);
  }

  Future<void> _accept() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await widget.service.acceptConsent(
        version: consentVersionFor(l10n.localeName),
      );
      await widget.onAccepted();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.consentSaveFailed)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          Gap.m,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Gap.xs,
                Text(body, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentCheck extends StatelessWidget {
  const _ConsentCheck({
    required this.value,
    required this.text,
    required this.onChanged,
  });

  final bool value;
  final String text;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(text),
    );
  }
}

class ConsentWithdrawnScreen extends StatelessWidget {
  const ConsentWithdrawnScreen({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.consentStudyAccess)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.block_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  Gap.m,
                  Text(
                    context.l10n.consentWithdrawnTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Gap.s,
                  Text(
                    context.l10n.consentWithdrawnBody,
                    textAlign: TextAlign.center,
                  ),
                  Gap.l,
                  FilledButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: Text(context.l10n.homeSignOut),
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
