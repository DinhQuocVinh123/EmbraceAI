import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../models/session_audio.dart';
import '../state/settings_store.dart';

class SessionSoundControls extends StatefulWidget {
  const SessionSoundControls({
    super.key,
    required this.settings,
    this.showDescription = true,
    this.onChanged,
  });

  final SettingsStore settings;
  final bool showDescription;
  final Future<void> Function()? onChanged;

  @override
  State<SessionSoundControls> createState() => _SessionSoundControlsState();
}

class _SessionSoundControlsState extends State<SessionSoundControls> {
  static const _previewDuration = Duration(seconds: 8);
  static const _previewOffset = Duration(seconds: 70);

  VideoPlayerController? _preview;
  Timer? _previewTimer;
  int _previewGeneration = 0;
  bool _routeIsActive = true;

  bool get _isPreviewing => _preview != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeIsActive = TickerMode.valuesOf(context).enabled;
    if (_routeIsActive && !routeIsActive) unawaited(_stopPreview());
    _routeIsActive = routeIsActive;
  }

  @override
  void dispose() {
    _previewGeneration++;
    _previewTimer?.cancel();
    final preview = _preview;
    _preview = null;
    if (preview != null) unawaited(preview.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: settings.soundOn,
          onChanged: (value) => _apply(() => settings.setSoundOn(value)),
          secondary: Icon(
            settings.soundOn
                ? Icons.volume_up_outlined
                : Icons.volume_off_outlined,
          ),
          title: const Text('Guided voice'),
          subtitle: widget.showDescription
              ? Text(
                  'Spoken narration during the practice',
                  style: theme.textTheme.bodySmall,
                )
              : null,
        ),
        if (settings.soundOn) ...[
          Gap.s,
          Text('Voice volume', style: theme.textTheme.labelLarge),
          Gap.s,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in SoundLevel.values)
                ChoiceChip(
                  label: Text(level.label),
                  selected: settings.soundLevel == level,
                  onSelected: (_) =>
                      _apply(() => settings.setSoundLevel(level)),
                ),
            ],
          ),
        ],
        const Divider(height: 32),
        Text('Background sound', style: theme.textTheme.labelLarge),
        if (widget.showDescription) ...[
          Gap.xs,
          Text(
            'Plays separately from the guided voice',
            style: theme.textTheme.bodySmall,
          ),
        ],
        Gap.s,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final sound in BackgroundSound.values)
              ChoiceChip(
                avatar: Icon(_backgroundIcon(sound), size: 18),
                label: Text(sound.label),
                selected: settings.backgroundSound == sound,
                onSelected: (_) => _selectBackground(sound),
              ),
          ],
        ),
        Gap.xs,
        Text(
          settings.backgroundSound.description,
          style: theme.textTheme.bodySmall,
        ),
        if (settings.backgroundSound != BackgroundSound.none) ...[
          Gap.s,
          OutlinedButton.icon(
            onPressed: _isPreviewing
                ? _stopPreview
                : () => _startPreview(settings.backgroundSound),
            icon: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.fast),
              child: Icon(
                _isPreviewing
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
                key: ValueKey(_isPreviewing),
              ),
            ),
            label: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.fast),
              child: Text(
                _isPreviewing ? 'Stop preview' : 'Preview sound',
                key: ValueKey(_isPreviewing),
              ),
            ),
          ),
          Gap.s,
          Text('Background volume', style: theme.textTheme.labelLarge),
          Gap.s,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in SoundLevel.values)
                ChoiceChip(
                  label: Text(_backgroundLevelLabel(level)),
                  selected: settings.backgroundLevel == level,
                  onSelected: (_) => _setBackgroundLevel(level),
                ),
            ],
          ),
        ],
      ],
    );
  }

  IconData _backgroundIcon(BackgroundSound sound) => switch (sound) {
    BackgroundSound.matchScene => Icons.auto_awesome_outlined,
    BackgroundSound.none => Icons.volume_off_outlined,
    BackgroundSound.countryside => Icons.music_note_outlined,
    BackgroundSound.ocean => Icons.waves_outlined,
    BackgroundSound.rain => Icons.water_drop_outlined,
  };

  String _backgroundLevelLabel(SoundLevel level) => switch (level) {
    SoundLevel.quiet => 'Low',
    SoundLevel.normal => 'Medium',
    SoundLevel.louder => 'High',
  };

  Future<void> _selectBackground(BackgroundSound sound) async {
    await _apply(() => widget.settings.setBackgroundSound(sound));
    if (!mounted) return;
    if (sound == BackgroundSound.none) {
      await _stopPreview();
    } else {
      await _startPreview(sound);
    }
  }

  Future<void> _setBackgroundLevel(SoundLevel level) async {
    await _apply(() => widget.settings.setBackgroundLevel(level));
    await _preview?.setVolume(widget.settings.effectiveBackgroundVolume);
  }

  Future<void> _startPreview(BackgroundSound sound) async {
    final asset = sound.assetFor(widget.settings.scene);
    if (asset == null) return;
    final generation = ++_previewGeneration;
    await _releasePreview();

    final next = VideoPlayerController.asset(
      asset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await next.initialize();
      await next.setLooping(true);
      await next.setVolume(widget.settings.effectiveBackgroundVolume);
      await next.seekTo(_previewOffset);
      if (!mounted || generation != _previewGeneration) {
        await next.dispose();
        return;
      }
      _preview = next;
      await next.play();
      if (!mounted || generation != _previewGeneration) {
        await next.dispose();
        return;
      }
      setState(() {});
      _previewTimer = Timer(_previewDuration, () => unawaited(_stopPreview()));
    } catch (_) {
      await next.dispose();
      if (!mounted || generation != _previewGeneration) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sound preview could not be played.')),
        snackBarAnimationStyle: AppMotion.style(context),
      );
    }
  }

  Future<void> _stopPreview() async {
    _previewGeneration++;
    await _releasePreview();
  }

  Future<void> _releasePreview() async {
    _previewTimer?.cancel();
    _previewTimer = null;
    final preview = _preview;
    _preview = null;
    if (mounted && preview != null) setState(() {});
    if (preview != null) {
      await preview.pause();
      await preview.dispose();
    }
  }

  Future<void> _apply(Future<void> Function() save) async {
    await save();
    await widget.onChanged?.call();
  }
}
