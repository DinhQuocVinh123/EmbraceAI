import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Bộ phát video giả, đủ để chạy [SessionController] trong test.
///
/// Không có thứ này thì lớp điều khiển — phần quyết định lúc nào dừng hỏi,
/// nhảy đi đâu, hiện câu phụ đề nào — hoàn toàn không được kiểm. Hai lỗi đã
/// lọt ra tới lúc chạy trên máy ảo đều nằm ở đó.
///
/// Hai điều cần biết về cách `video_player` hoạt động, vì nó quyết định hình
/// dạng của lớp này:
///
///  - Vị trí phát **không** đến từ sự kiện. Bộ điều khiển thật tự hỏi
///    [getPosition] mỗi 500 ms bằng một `Timer.periodic`. Nên test phải chạy
///    dưới đồng hồ giả của `testWidgets` và nhích bằng `tester.pump`, chứ
///    không thể chỉ bắn sự kiện.
///  - Sự kiện `initialized` chỉ tới tay người nghe nếu nó được phát **sau**
///    khi họ đăng ký. Luồng ở đây phát nó ra trước rồi mới nối vào luồng
///    chung, nên không phụ thuộc vào thứ tự microtask.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  FakeVideoPlayerPlatform({required this.duration});

  final Duration duration;

  int _nextId = 1;
  final Map<int, _FakePlayerState> _players = {};

  /// Những mốc đã được tua tới, theo thứ tự — để test biết nó nhảy đi đâu.
  final List<Duration> seeks = [];

  /// Các file đã được mở, để kiểm mỗi bối cảnh dùng đúng video của nó.
  final List<String> opened = [];
  final List<bool> mixWithOthersValues = [];

  _FakePlayerState get _primary => _players[1]!;

  Duration get position => _primary.position;
  bool get isPlaying => _primary.playing;
  double get volume => _primary.volume;

  set position(Duration value) {
    _primary.position = value > duration ? duration : value;
  }

  double volumeFor(String source) => _stateFor(source).volume;
  bool isPlayingSource(String source) => _stateFor(source).playing;
  Duration positionFor(String source) => _stateFor(source).position;

  _FakePlayerState _stateFor(String source) =>
      _players.values.lastWhere((state) => state.source == source);

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<int?> create(DataSource dataSource) async =>
      _create(dataSource.asset ?? dataSource.uri ?? '');

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async =>
      _create(options.dataSource.asset ?? options.dataSource.uri ?? '');

  int _create(String source) {
    opened.add(source);
    final id = _nextId++;
    _players[id] = _FakePlayerState(source);
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) async* {
    yield VideoEvent(
      eventType: VideoEventType.initialized,
      duration: duration,
      size: const Size(1280, 720),
      rotationCorrection: 0,
    );
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {
    _players[playerId]!.playing = true;
  }

  @override
  Future<void> pause(int playerId) async {
    _players[playerId]!.playing = false;
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    _players[playerId]!.volume = volume;
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    seeks.add(position);
    _players[playerId]!.position = position;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async =>
      _players[playerId]!.position;

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.shrink();

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {
    mixWithOthersValues.add(mixWithOthers);
  }
}

class _FakePlayerState {
  _FakePlayerState(this.source);

  final String source;
  Duration position = Duration.zero;
  bool playing = false;
  double volume = 1;
}

/// Cho video chạy tới [target], nhích từng bước như bộ phát thật.
///
/// Nhảy thẳng một phát từ 0 tới cuối sẽ bỏ lọt mọi mốc cần kiểm, nên nó đi
/// từng bước và để bộ điều khiển kịp hỏi vị trí sau mỗi bước. Dừng ngay khi
/// video bị tạm dừng — tức là lúc app chen vào hỏi.
Future<void> runTo(
  WidgetTester tester,
  FakeVideoPlayerPlatform fake,
  Duration target, {
  Duration step = const Duration(seconds: 1),
}) async {
  while (fake.position < target && fake.isPlaying) {
    final next = fake.position + step;
    fake.position = next > target ? target : next;
    // Nhiều hơn 500 ms để chắc chắn vòng hỏi vị trí chạy đúng một lần, rồi
    // một nhịp nữa cho phần xử lý sau `await` của nó.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }
}
