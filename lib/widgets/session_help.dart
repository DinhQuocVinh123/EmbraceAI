import 'package:flutter/material.dart';

import '../state/settings_store.dart';
import 'session_sound_controls.dart';

class SessionHelp extends StatelessWidget {
  const SessionHelp({super.key, required this.settings, this.onAudioChanged});

  final SettingsStore settings;
  final Future<void> Function()? onAudioChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => FractionallySizedBox(
        heightFactor: 0.85,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Help',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close help',
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    const Text(
                      'Take your time. Find a comfortable position and let your '
                      'breathing stay natural. You can leave the practice whenever '
                      'you need to.',
                    ),
                    const SizedBox(height: 16),
                    SessionSoundControls(
                      settings: settings,
                      showDescription: false,
                      onChanged: onAudioChanged,
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Easier view'),
                      value: settings.isAssisted,
                      onChanged: (enabled) => enabled
                          ? settings.enableAssistedView()
                          : settings.resetView(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Text size',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final scale in SettingsStore.textScaleSteps)
                          ChoiceChip(
                            label: Text('${(scale * 100).round()}%'),
                            selected: settings.textScale == scale,
                            onSelected: (_) => settings.setTextScale(scale),
                          ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Brighter picture'),
                      value: settings.highClarity,
                      onChanged: settings.setHighClarity,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show captions'),
                      value: settings.captionsOn,
                      onChanged: settings.setCaptionsOn,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reduce motion'),
                      value: settings.reduceMotion,
                      onChanged: settings.setReduceMotion,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Return to practice'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('End practice'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
