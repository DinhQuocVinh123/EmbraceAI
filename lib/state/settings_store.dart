import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_audio.dart';
import '../models/session_scene.dart';

enum SoundLevel {
  quiet('Quiet', 'Soft volume', 0.35),
  normal('Normal', 'Comfortable volume', 0.70),
  louder('Louder', 'Full volume', 1.0);

  const SoundLevel(this.label, this.description, this.volume);

  final String label;
  final String description;
  final double volume;

  static SoundLevel fromId(String? id) => SoundLevel.values.firstWhere(
    (level) => level.name == id,
    orElse: () => SoundLevel.normal,
  );
}

/// Tuỳ chọn hiển thị, đặt riêng khỏi dữ liệu nhật ký.
///
/// Các mục ở đây trả lời trực tiếp góp ý của hội đồng: chữ to hơn (Dr. Hue),
/// ảnh nền rõ hơn (Dr. Hue), và một nút chuyển nhanh sang chế độ dễ nhìn cho
/// người thị lực kém. Mọi thay đổi có hiệu lực ngay, không cần khởi động lại.
class SettingsStore extends ChangeNotifier {
  static const _textScaleKey = 'settings.textScale';
  static const _highClarityKey = 'settings.highClarity';
  static const _captionsKey = 'settings.captions';
  static const _sceneKey = 'settings.scene';
  static const _soundOnKey = 'settings.soundOn';
  static const _soundLevelKey = 'settings.soundLevel';
  static const _backgroundSoundKey = 'settings.backgroundSound';
  static const _backgroundLevelKey = 'settings.backgroundLevel';
  static const _reduceMotionKey = 'settings.reduceMotion';

  /// Các nấc cỡ chữ, hiện cho người dùng chọn thay vì một thanh trượt vô định.
  static const textScaleSteps = <double>[1.0, 1.25, 1.5, 1.75, 2.0];

  double _textScale = 1.0;
  bool _highClarity = false;
  bool _captionsOn = true;
  SessionScene _scene = SessionScene.countryside;
  bool _soundOn = true;
  SoundLevel _soundLevel = SoundLevel.normal;
  BackgroundSound _backgroundSound = BackgroundSound.matchScene;
  SoundLevel _backgroundLevel = SoundLevel.normal;
  bool _reduceMotion = false;

  double get textScale => _textScale;
  bool get highClarity => _highClarity;
  bool get captionsOn => _captionsOn;
  SessionScene get scene => _scene;
  bool get soundOn => _soundOn;
  SoundLevel get soundLevel => _soundLevel;
  double get effectiveVoiceVolume => _soundOn ? _soundLevel.volume : 0;
  BackgroundSound get backgroundSound => _backgroundSound;
  SoundLevel get backgroundLevel => _backgroundLevel;
  double get effectiveBackgroundVolume =>
      _backgroundSound == BackgroundSound.none ? 0 : _backgroundLevel.volume;
  bool get reduceMotion => _reduceMotion;

  /// Đang bật ít nhất một hỗ trợ nhìn — dùng để hiện nhãn "đang ở chế độ dễ nhìn".
  bool get isAssisted => _highClarity || _textScale > 1.0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _textScale = prefs.getDouble(_textScaleKey) ?? 1.0;
    _highClarity = prefs.getBool(_highClarityKey) ?? false;
    _captionsOn = prefs.getBool(_captionsKey) ?? true;
    _scene = SessionScene.fromId(prefs.getString(_sceneKey));
    _soundOn = prefs.getBool(_soundOnKey) ?? true;
    _soundLevel = SoundLevel.fromId(prefs.getString(_soundLevelKey));
    _backgroundSound = BackgroundSound.fromId(
      prefs.getString(_backgroundSoundKey),
    );
    _backgroundLevel = SoundLevel.fromId(prefs.getString(_backgroundLevelKey));
    _reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    if (value == _textScale) return;
    _textScale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, value);
  }

  Future<void> setHighClarity(bool value) async {
    if (value == _highClarity) return;
    _highClarity = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highClarityKey, value);
  }

  Future<void> setCaptionsOn(bool value) async {
    if (value == _captionsOn) return;
    _captionsOn = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_captionsKey, value);
  }

  Future<void> setScene(SessionScene value) async {
    if (value == _scene) return;
    _scene = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sceneKey, value.id);
  }

  Future<void> setSoundOn(bool value) async {
    if (value == _soundOn) return;
    _soundOn = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundOnKey, value);
  }

  Future<void> setSoundLevel(SoundLevel value) async {
    if (value == _soundLevel) return;
    _soundLevel = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundLevelKey, value.name);
  }

  Future<void> setBackgroundSound(BackgroundSound value) async {
    if (value == _backgroundSound) return;
    _backgroundSound = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundSoundKey, value.name);
  }

  Future<void> setBackgroundLevel(SoundLevel value) async {
    if (value == _backgroundLevel) return;
    _backgroundLevel = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundLevelKey, value.name);
  }

  Future<void> setReduceMotion(bool value) async {
    if (value == _reduceMotion) return;
    _reduceMotion = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, value);
  }

  /// Bật trọn gói hỗ trợ nhìn bằng một thao tác — đúng yêu cầu "hit a button
  /// to access a version with clearer, brighter images and bigger texts".
  Future<void> enableAssistedView() async {
    await setHighClarity(true);
    await setTextScale(1.5);
  }

  Future<void> resetView() async {
    await setHighClarity(false);
    await setTextScale(1.0);
  }
}
