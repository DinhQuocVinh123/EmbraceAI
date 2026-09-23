import 'session_scene.dart';

enum BackgroundSound {
  matchScene(
    'Match video',
    'Countryside music or ocean waves chosen with the picture',
  ),
  none('None', 'Narration without a background sound'),
  countryside('Countryside', 'Soft instrumental countryside ambience'),
  ocean('Ocean waves', 'Slow waves and a light sea breeze'),
  rain('Gentle rain', 'Steady rain without thunder');

  const BackgroundSound(this.label, this.description);

  final String label;
  final String description;

  String? assetFor(SessionScene scene) => switch (this) {
    BackgroundSound.matchScene =>
      scene == SessionScene.countryside
          ? BackgroundSound.countryside.assetFor(scene)
          : BackgroundSound.ocean.assetFor(scene),
    BackgroundSound.none => null,
    BackgroundSound.countryside => 'assets/audio/ambient_countryside.m4a',
    BackgroundSound.ocean => 'assets/audio/ambient_ocean.m4a',
    BackgroundSound.rain => 'assets/audio/ambient_rain.m4a',
  };

  static BackgroundSound fromId(String? id) =>
      BackgroundSound.values.firstWhere(
        (sound) => sound.name == id,
        orElse: () => BackgroundSound.matchScene,
      );
}
