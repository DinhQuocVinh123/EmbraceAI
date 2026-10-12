import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../state/settings_store.dart';
import 'session_sound_controls.dart';

class SessionHelp extends StatelessWidget {
  const SessionHelp({super.key, required this.settings, this.onAudioChanged});

  final SettingsStore settings;
  final Future<void> Function()? onAudioChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                        l10n.helpTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.helpClose,
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
                    Text(l10n.helpBody),
                    const SizedBox(height: 16),
                    SessionSoundControls(
                      settings: settings,
                      showDescription: false,
                      onChanged: onAudioChanged,
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.helpEasierView),
                      value: settings.isAssisted,
                      onChanged: (enabled) => enabled
                          ? settings.enableAssistedView()
                          : settings.resetView(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.welcomeTextSize,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final scale in SettingsStore.textScaleSteps)
                          ChoiceChip(
                            label: Text(
                              l10n.percentValue((scale * 100).round()),
                            ),
                            selected: settings.textScale == scale,
                            onSelected: (_) => settings.setTextScale(scale),
                          ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.helpBrighterPicture),
                      value: settings.highClarity,
                      onChanged: settings.setHighClarity,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.welcomeShowCaptions),
                      value: settings.captionsOn,
                      onChanged: settings.setCaptionsOn,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.welcomeReduceMotion),
                      value: settings.reduceMotion,
                      onChanged: settings.setReduceMotion,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l10n.helpReturn),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(l10n.helpEnd),
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
