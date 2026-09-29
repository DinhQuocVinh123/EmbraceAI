import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/study_assessment.dart';
import '../services/study_assessment_service.dart';
import 'demographics_screen.dart';
import 'final_assessment_screen.dart';
import 'home_screen.dart';
import 'participant_consent_screen.dart';

class ParticipantStudyGate extends StatefulWidget {
  const ParticipantStudyGate({
    super.key,
    required this.participantCode,
    required this.onSignOut,
  });

  final String participantCode;
  final Future<void> Function() onSignOut;

  @override
  State<ParticipantStudyGate> createState() => _ParticipantStudyGateState();
}

class _ParticipantStudyGateState extends State<ParticipantStudyGate> {
  bool _deferredFinalAssessment = false;
  StudyAssessmentService? _service;
  Stream<StudyProgress>? _progressStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<StudyAssessmentService>();
    if (identical(service, _service)) return;
    _service = service;
    _progressStream = service.watchProgress(widget.participantCode);
  }

  @override
  Widget build(BuildContext context) {
    final service = _service!;
    return StreamBuilder<StudyProgress>(
      stream: _progressStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StudyGateError(onSignOut: widget.onSignOut);
        }
        final progress = snapshot.data;
        if (progress == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (progress.consentWithdrawn) {
          return ConsentWithdrawnScreen(onSignOut: widget.onSignOut);
        }
        if (progress.needsConsent) {
          return ParticipantConsentScreen(
            service: service,
            onAccepted: () => setState(() {}),
            onSignOut: widget.onSignOut,
          );
        }
        if (progress.needsDemographics) {
          return DemographicsScreen(
            service: service,
            onSubmitted: () => setState(() {}),
            onSignOut: widget.onSignOut,
          );
        }
        if (progress.needsFinalAssessment && !_deferredFinalAssessment) {
          return FinalAssessmentScreen(
            service: service,
            onSubmitted: () => setState(() {}),
            onDefer: () => setState(() => _deferredFinalAssessment = true),
            onSignOut: widget.onSignOut,
          );
        }
        return HomeScreen(
          participantCode: widget.participantCode,
          onSignOut: widget.onSignOut,
          finalAssessmentDue: progress.needsFinalAssessment,
          onOpenFinalAssessment: progress.needsFinalAssessment
              ? () => setState(() => _deferredFinalAssessment = false)
              : null,
        );
      },
    );
  }
}

class _StudyGateError extends StatelessWidget {
  const _StudyGateError({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EmbraceAI'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Your study information could not be loaded. Check your connection and try again.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
