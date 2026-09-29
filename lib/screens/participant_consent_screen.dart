import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/consent.dart';
import '../services/study_assessment_service.dart';
import '../widgets/blocking_loading_overlay.dart';

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
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Study information and consent'),
            actions: [
              IconButton(
                tooltip: 'Sign out',
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
                      'Before you take part',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Gap.s,
                    Text(
                      'Please read this information carefully. Taking part is '
                      'voluntary, and choosing not to take part will not affect '
                      'your healthcare.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Gap.xl,
                    const _InformationSection(
                      icon: Icons.science_outlined,
                      title: 'Purpose',
                      body:
                          'This prototype provides an AI-guided relaxation exercise and asks about your experience so the research team can evaluate and improve it.',
                    ),
                    const _InformationSection(
                      icon: Icons.volunteer_activism_outlined,
                      title: 'Your choice',
                      body:
                          'You may stop a session at any time, leave optional questions unanswered, or contact the research team member who gave you access if you wish to withdraw.',
                    ),
                    const _InformationSection(
                      icon: Icons.medical_information_outlined,
                      title: 'Medical safety',
                      body:
                          'This is not a medical intervention. If you experience any discomfort, please stop immediately and seek help from your medical team.',
                    ),
                    const _InformationSection(
                      icon: Icons.shield_outlined,
                      title: 'Information collected',
                      body:
                          'Your responses are linked to your study-issued Participant ID. The app collects the approved demographic and health form, session activity, mood ratings and study questionnaires. It does not ask for your name, personal email, phone number or medical record number.',
                    ),
                    Gap.l,
                    Text(
                      'Please confirm each statement',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap.s,
                    _ConsentCheck(
                      value: _checks[0],
                      text: 'I have read and understood the information above.',
                      onChanged: (value) => _setCheck(0, value),
                    ),
                    _ConsentCheck(
                      value: _checks[1],
                      text:
                          'I understand that taking part is voluntary and that I may stop at any time.',
                      onChanged: (value) => _setCheck(1, value),
                    ),
                    _ConsentCheck(
                      value: _checks[2],
                      text:
                          'I understand that this relaxation exercise is not medical treatment.',
                      onChanged: (value) => _setCheck(2, value),
                    ),
                    _ConsentCheck(
                      value: _checks[3],
                      text:
                          'I consent to the research team collecting and using the information described above for this study.',
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
                      label: const Text('I consent and continue'),
                    ),
                    Gap.s,
                    TextButton(
                      onPressed: _saving ? null : widget.onSignOut,
                      child: const Text('Exit without consenting'),
                    ),
                    Gap.m,
                    Text(
                      'Consent record version: $studyConsentVersion',
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
          const BlockingLoadingOverlay(message: 'Saving your consent...'),
      ],
    );
  }

  void _setCheck(int index, bool? value) {
    setState(() => _checks[index] = value ?? false);
  }

  Future<void> _accept() async {
    setState(() => _saving = true);
    try {
      await widget.service.acceptConsent();
      await widget.onAccepted();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your consent could not be recorded. Try again.'),
        ),
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
      appBar: AppBar(title: const Text('Study access')),
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
                    'Consent has been withdrawn',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Gap.s,
                  const Text(
                    'This study account cannot be used. Contact the research team member who provided your access if you believe this is incorrect.',
                    textAlign: TextAlign.center,
                  ),
                  Gap.l,
                  FilledButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
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
