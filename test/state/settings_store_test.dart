import 'package:embrace_ai/models/session_audio.dart';
import 'package:embrace_ai/state/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sound defaults are comfortable and enabled', () {
    final settings = SettingsStore();
    expect(settings.soundOn, isTrue);
    expect(settings.soundLevel, SoundLevel.normal);
    expect(settings.effectiveVoiceVolume, 0.70);
    expect(settings.backgroundSound, BackgroundSound.matchScene);
    expect(settings.backgroundLevel, SoundLevel.normal);
    expect(settings.effectiveBackgroundVolume, 0.70);
  });

  test('sound and volume choices persist', () async {
    final first = SettingsStore();
    await first.setSoundLevel(SoundLevel.louder);
    await first.setSoundOn(false);
    await first.setBackgroundSound(BackgroundSound.rain);
    await first.setBackgroundLevel(SoundLevel.quiet);

    final restored = SettingsStore();
    await restored.load();
    expect(restored.soundLevel, SoundLevel.louder);
    expect(restored.soundOn, isFalse);
    expect(restored.effectiveVoiceVolume, 0);
    expect(restored.backgroundSound, BackgroundSound.rain);
    expect(restored.backgroundLevel, SoundLevel.quiet);
    expect(restored.effectiveBackgroundVolume, 0.35);

    await restored.setSoundOn(true);
    expect(restored.effectiveVoiceVolume, 1);

    await restored.setBackgroundSound(BackgroundSound.none);
    expect(restored.effectiveBackgroundVolume, 0);
  });

  test('reduce motion persists independently from easier view', () async {
    final first = SettingsStore();
    await first.setReduceMotion(true);

    final restored = SettingsStore();
    await restored.load();
    expect(restored.reduceMotion, isTrue);
    expect(restored.isAssisted, isFalse);

    await restored.enableAssistedView();
    await restored.resetView();
    expect(restored.reduceMotion, isTrue);
  });
}
