enum BreathingPhase { inhale, exhale }

class BreathingCue {
  const BreathingCue({required this.phase, required this.progress});

  final BreathingPhase phase;

  /// Progress through the current five-second inhale or exhale phase.
  final double progress;

  String get label => switch (phase) {
    BreathingPhase.inhale => 'Breathe in',
    BreathingPhase.exhale => 'Breathe out',
  };
}
