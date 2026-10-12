import 'session_scene.dart';

/// Giọng hướng dẫn theo ngôn ngữ đang dùng. Giọng tiếng Anh nằm sẵn trong
/// video nên không có file riêng. Giọng tiếng Việt là một file đọc đúng các
/// mốc phụ đề, tạo bằng `tools/voice/synth_narration_vi.py`; sửa câu tiếng
/// Việt trong kịch bản thì tạo lại file này.
String? narrationAssetFor(String languageCode) =>
    languageCode == 'vi' ? 'assets/audio/narration_vi.m4a' : null;

enum BackgroundSound {
  // Tên và mô tả hiển thị nằm ở lib/l10n/labels.dart.
  matchScene,
  none,
  countryside,
  ocean,
  rain;

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
