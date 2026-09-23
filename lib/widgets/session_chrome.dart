import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../models/breathing_cue.dart';

/// Các lớp phủ của màn hình thiền, tách riêng để vừa dùng trong app vừa dùng
/// để chụp màn hình được — ảnh chụp và app chạy thật dùng chung một đoạn mã,
/// nên không thể lệch nhau.

/// Tăng tương phản và độ sáng cho người khó nhìn.
///
/// Hội đồng nhận xét nhiều khung hình bị mờ sương (Dr. Hue). Xử lý ngay lúc
/// phát bằng ma trận màu nên không cần dựng thêm một bản video thứ hai.
class ClarityFilter extends StatelessWidget {
  const ClarityFilter({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  static const _contrast = 1.28;
  static const _brightness = 14.0;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    // out = (in - 128) * contrast + brightness + 128
    const t = 128 * (1 - _contrast) + _brightness;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        _contrast,
        0,
        0,
        0,
        t,
        0,
        _contrast,
        0,
        0,
        t,
        0,
        0,
        _contrast,
        0,
        t,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: child,
    );
  }
}

/// Các mức phủ tối tối thiểu cho lớp chữ nằm trên video.
///
/// Không phải chọn cho đẹp mắt. Phụ đề được đặt theo toạ độ màn hình chứ
/// không theo khung hình, nên khi cửa sổ thấp và ngang nó đè lên chính hình
/// video. Đo trên toàn bộ 8 phút của cả hai bối cảnh, chỗ sáng nhất mà chữ có
/// thể rơi vào cho độ chói 0.53 — chữ trắng đặt thẳng lên đó chỉ đạt 1.81:1,
/// trong khi SC 1.4.3 đòi 4.5:1. Các mức dưới đây được tính ngược từ trường
/// hợp xấu nhất là nền trắng tinh, nên chúng đúng với mọi khung hình.
class SessionScrim {
  const SessionScrim._();

  /// Tấm nền sau phụ đề. Nền trắng phủ mức này còn lại độ chói 0.119, chữ
  /// trắng đạt 6.2:1. Trên dải đen hai bên video thì nó vô hình.
  static const captionPlate = 0.62;

  /// Mức phủ của hai thanh trên và dưới, giữ nguyên tới hết vùng có chữ rồi
  /// mới nhoè đi. Nền trắng phủ mức này cho chữ trắng 6.9:1.
  static const bar = 0.65;

  /// Phần chiều cao thanh được phủ đều trước khi nhoè — chữ phải nằm gọn
  /// trong đó.
  static const barHold = 0.62;
}

/// Phụ đề do app vẽ — cỡ chữ theo cài đặt, trình đọc màn hình đọc được.
class SessionCaption extends StatelessWidget {
  const SessionCaption({super.key, required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.standard),
      child: text == null
          ? const SizedBox(key: ValueKey('empty'), height: 0)
          : Semantics(
              liveRegion: true,
              label: 'Caption: $text',
              excludeSemantics: true,
              child: Container(
                key: ValueKey(text),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: SessionScrim.captionPlate,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  text!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
    );
  }
}

/// Thanh trên: đang ở phần nào, và nút dừng luôn nhìn thấy.
class SessionTopBar extends StatelessWidget {
  const SessionTopBar({
    super.key,
    required this.beatNumber,
    required this.beatTitle,
    required this.totalBeats,
    this.onStop,
    this.onHelp,
  });

  final int beatNumber;
  final String beatTitle;
  final int totalBeats;
  final VoidCallback? onStop;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: SessionScrim.bar),
              Colors.black.withValues(alpha: SessionScrim.bar),
              Colors.transparent,
            ],
            stops: const [0.0, SessionScrim.barHold, 1.0],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Semantics(
                  liveRegion: true,
                  header: true,
                  label: 'Part $beatNumber of $totalBeats. $beatTitle',
                  excludeSemantics: true,
                  child: Text(
                    'Part $beatNumber of $totalBeats · $beatTitle',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Help',
              onPressed: onHelp,
              icon: const Icon(Icons.help_outline, color: Colors.white),
            ),
            TextButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text(
                'Stop',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh dưới: nút tạm dừng và tiến độ buổi tập.
class SessionBottomBar extends StatelessWidget {
  const SessionBottomBar({
    super.key,
    required this.position,
    required this.total,
    required this.isPlaying,
    this.onTogglePlay,
  });

  final Duration position;
  final Duration total;
  final bool isPlaying;
  final VoidCallback? onTogglePlay;

  static String fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  static String semanticTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final parts = <String>[];
    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? "minute" : "minutes"}');
    }
    if (seconds > 0 || parts.isEmpty) {
      parts.add('$seconds ${seconds == 1 ? "second" : "seconds"}');
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final fraction = total.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / total.inMilliseconds;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: SessionScrim.bar),
              Colors.black.withValues(alpha: SessionScrim.bar),
              Colors.transparent,
            ],
            stops: const [0.0, SessionScrim.barHold, 1.0],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              iconSize: 36,
              color: Colors.white,
              tooltip: isPlaying ? 'Pause' : 'Resume',
              onPressed: onTogglePlay,
              icon: AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.fast),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  key: ValueKey(isPlaying),
                ),
              ),
            ),
            Gap.s,
            Expanded(
              child: Semantics(
                label: 'Session progress',
                value: '${semanticTime(position)} of ${semanticTime(total)}',
                excludeSemantics: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: fraction.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white54,
                      ),
                    ),
                    Gap.xs,
                    Text(
                      '${fmt(position)} / ${fmt(total)}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ghép đủ các lớp của màn hình thiền quanh một bề mặt video bất kỳ.
///
/// Trong app thật [videoSurface] là widget phát video; khi chụp màn hình nó là
/// một khung hình tĩnh lấy ra từ chính video đó.
class SessionStage extends StatelessWidget {
  const SessionStage({
    super.key,
    required this.videoSurface,
    required this.aspectRatio,
    required this.beatNumber,
    required this.beatTitle,
    required this.totalBeats,
    required this.position,
    required this.total,
    required this.isPlaying,
    this.highClarity = false,
    this.captionsOn = true,
    this.caption,
    this.breathingCue,
    this.reduceMotion = false,
    this.onStop,
    this.onTogglePlay,
    this.onHelp,
  });

  final Widget videoSurface;
  final double aspectRatio;
  final int beatNumber;
  final String beatTitle;
  final int totalBeats;
  final Duration position;
  final Duration total;
  final bool isPlaying;
  final bool highClarity;
  final bool captionsOn;
  final String? caption;
  final BreathingCue? breathingCue;
  final bool reduceMotion;
  final VoidCallback? onStop;
  final VoidCallback? onTogglePlay;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final captionFontSize = MediaQuery.textScalerOf(context).scale(21);
    final captionScale = captionFontSize / 21;
    final reservedCaptionLines = (4 + (captionScale - 1) * 2).clamp(4.0, 7.0);
    final captionRailHeight =
        (32 + captionFontSize * 1.35 * reservedCaptionLines)
            .clamp(136.0, 420.0)
            .floorToDouble();

    return Column(
      children: [
        SessionTopBar(
          beatNumber: beatNumber,
          beatTitle: beatTitle,
          totalBeats: totalBeats,
          onStop: onStop,
          onHelp: onHelp,
        ),
        Expanded(
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ExcludeSemantics(
                          child: ClarityFilter(
                            enabled: highClarity,
                            child: videoSurface,
                          ),
                        ),
                        if (breathingCue case final cue?)
                          Center(
                            child: BreathingGuide(
                              cue: cue,
                              reduceMotion: reduceMotion,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (captionsOn)
                  SizedBox(
                    height: captionRailHeight,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SessionCaption(text: caption),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SessionBottomBar(
          position: position,
          total: total,
          isPlaying: isPlaying,
          onTogglePlay: onTogglePlay,
        ),
      ],
    );
  }
}

class BreathingGuide extends StatelessWidget {
  const BreathingGuide({
    super.key,
    required this.cue,
    required this.reduceMotion,
  });

  final BreathingCue cue;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final directedProgress = cue.phase == BreathingPhase.inhale
        ? cue.progress
        : 1 - cue.progress;
    final eased = Curves.easeInOut.transform(directedProgress.clamp(0.0, 1.0));
    final scale = reduceMotion ? 1.0 : 0.86 + eased * 0.18;

    return Semantics(
      liveRegion: true,
      label: 'Breathing guide: ${cue.label}',
      excludeSemantics: true,
      child: Transform.scale(
        key: const ValueKey('breathing-guide-ring'),
        scale: scale,
        child: Container(
          width: 116,
          height: 116,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.42),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 12, spreadRadius: 2),
            ],
          ),
          child: Text(
            cue.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
