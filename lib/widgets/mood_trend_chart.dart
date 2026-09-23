import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../models/mood.dart';
import '../state/journal_store.dart';

/// Đường tâm trạng trung bình theo ngày.
///
/// Chỉ một chuỗi dữ liệu nên không cần chú giải; tiêu đề phía trên đã nói rõ
/// đang xem gì. Ngày không ghi để đứt đoạn thay vì nối thẳng qua — nối qua là
/// bịa ra dữ liệu không tồn tại.
class MoodTrendChart extends StatefulWidget {
  const MoodTrendChart({super.key, required this.data});

  final List<DailyAverage> data;

  @override
  State<MoodTrendChart> createState() => _MoodTrendChartState();
}

class _MoodTrendChartState extends State<MoodTrendChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 180,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Semantics(
            container: true,
            label: 'Mood trend chart',
            value: _semanticValue(),
            increasedValue: _semanticAdjacentValue(1),
            decreasedValue: _semanticAdjacentValue(-1),
            hint: 'Use left and right arrows, or adjust, to read each day.',
            onIncrease: _recordedIndexes.isEmpty
                ? null
                : () => _moveSelection(1),
            onDecrease: _recordedIndexes.isEmpty
                ? null
                : () => _moveSelection(-1),
            child: Focus(
              onKeyEvent: _handleKeyEvent,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) =>
                    _select(d.localPosition.dx, constraints.maxWidth),
                onTapUp: (_) => _clear(),
                onTapCancel: _clear,
                onHorizontalDragUpdate: (d) =>
                    _select(d.localPosition.dx, constraints.maxWidth),
                onHorizontalDragEnd: (_) => _clear(),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 180),
                  painter: _TrendPainter(
                    data: widget.data,
                    selected: _selected,
                    gridColor: scheme.outlineVariant,
                    brightness: Theme.of(context).brightness,
                    labelColor: scheme.onSurfaceVariant,
                    surfaceColor: scheme.surfaceContainerLow,
                    tooltipColor: scheme.inverseSurface,
                    tooltipTextColor: scheme.onInverseSurface,
                    textDirection: Directionality.of(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _clear() {
    if (_selected != null) setState(() => _selected = null);
  }

  void _select(double dx, double width) {
    if (widget.data.isEmpty) return;
    final plotWidth = width - _TrendPainter.padLeft - _TrendPainter.padRight;
    if (plotWidth <= 0) return;
    final step = widget.data.length > 1
        ? plotWidth / (widget.data.length - 1)
        : plotWidth;
    final index = ((dx - _TrendPainter.padLeft) / step).round().clamp(
      0,
      widget.data.length - 1,
    );
    // Ngày trống thì không có gì để hiện.
    if (widget.data[index].average == null) {
      _clear();
      return;
    }
    if (index != _selected) setState(() => _selected = index);
  }

  List<int> get _recordedIndexes => [
    for (var i = 0; i < widget.data.length; i++)
      if (widget.data[i].average != null) i,
  ];

  void _moveSelection(int direction) {
    final indexes = _recordedIndexes;
    if (indexes.isEmpty) return;
    final current = _selected == null ? -1 : indexes.indexOf(_selected!);
    final next = current < 0
        ? (direction > 0 ? 0 : indexes.length - 1)
        : (current + direction).clamp(0, indexes.length - 1);
    setState(() => _selected = indexes[next]);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _semanticValue() {
    final selected = _selected;
    if (selected != null && widget.data[selected].average != null) {
      return _semanticDayValue(selected);
    }
    final recorded = widget.data.where((day) => day.average != null).toList();
    if (recorded.isEmpty) return 'No recorded days';
    return recorded
        .map(
          (day) =>
              '${DateFormat('d MMM').format(day.date)}, '
              '${day.average!.toStringAsFixed(1)} out of 5',
        )
        .join('; ');
  }

  String? _semanticAdjacentValue(int direction) {
    final indexes = _recordedIndexes;
    if (indexes.isEmpty) return null;
    final current = _selected == null ? -1 : indexes.indexOf(_selected!);
    final next = current < 0
        ? (direction > 0 ? 0 : indexes.length - 1)
        : (current + direction).clamp(0, indexes.length - 1);
    return _semanticDayValue(indexes[next]);
  }

  String _semanticDayValue(int index) {
    final day = widget.data[index];
    return '${DateFormat('d MMMM').format(day.date)}, '
        '${day.average!.toStringAsFixed(1)} out of 5';
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.data,
    required this.selected,
    required this.gridColor,
    required this.brightness,
    required this.labelColor,
    required this.surfaceColor,
    required this.tooltipColor,
    required this.tooltipTextColor,
    required this.textDirection,
  });

  final List<DailyAverage> data;
  final int? selected;
  final Color gridColor;
  final Brightness brightness;
  final Color labelColor;
  final Color surfaceColor;
  final Color tooltipColor;
  final Color tooltipTextColor;
  final TextDirection textDirection;

  static const padLeft = 28.0;
  static const padRight = 12.0;
  static const padTop = 14.0;
  static const padBottom = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final plot = Rect.fromLTRB(
      padLeft,
      padTop,
      size.width - padRight,
      size.height - padBottom,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    _paintGrid(canvas, plot);
    final points = _points(plot);
    _paintLine(canvas, points);
    _paintDots(canvas, points);
    _paintDateLabels(canvas, plot);
    _paintSelection(canvas, plot, points, size);
  }

  /// Toạ độ y cho điểm tâm trạng 1..5 — điểm 5 nằm trên cùng.
  double _y(Rect plot, double score) =>
      plot.bottom - ((score - 1) / 4) * plot.height;

  double _x(Rect plot, int index) => data.length > 1
      ? plot.left + (plot.width / (data.length - 1)) * index
      : plot.center.dx;

  List<Offset?> _points(Rect plot) {
    return [
      for (var i = 0; i < data.length; i++)
        if (data[i].average != null)
          Offset(_x(plot, i), _y(plot, data[i].average!))
        else
          null,
    ];
  }

  void _paintGrid(Canvas canvas, Rect plot) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    // Ba mốc thôi: tệ / bình thường / tuyệt vời. Năm đường là quá nhiều mực.
    for (final score in const [1, 3, 5]) {
      final y = _y(plot, score.toDouble());
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), paint);
      _drawText(
        canvas,
        Mood.fromScore(score).emoji,
        Offset(0, y - 8),
        fontSize: 12,
        color: labelColor,
      );
    }
  }

  void _paintLine(Canvas canvas, List<Offset?> points) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Mood.colorForAverage(_overallAverage(), brightness);

    Path? path;
    for (final point in points) {
      if (point == null) {
        if (path != null) canvas.drawPath(path, paint);
        path = null;
        continue;
      }
      if (path == null) {
        path = Path()..moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    if (path != null) canvas.drawPath(path, paint);
  }

  void _paintDots(Canvas canvas, List<Offset?> points) {
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      if (point == null) continue;
      // Vòng nền tách các chấm nằm sát nhau khi đường dốc.
      canvas.drawCircle(point, 5, Paint()..color = surfaceColor);
      canvas.drawCircle(
        point,
        4,
        Paint()..color = Mood.colorForAverage(data[i].average!, brightness),
      );
    }
  }

  void _paintDateLabels(Canvas canvas, Rect plot) {
    // Chỉ dán nhãn đầu / giữa / cuối để trục không bị chen chữ.
    final indexes = data.length > 2
        ? <int>{0, data.length ~/ 2, data.length - 1}
        : <int>{0, data.length - 1};
    final format = DateFormat('d/M');
    for (final index in indexes) {
      _drawText(
        canvas,
        format.format(data[index].date),
        Offset(_x(plot, index) - 14, plot.bottom + 8),
        fontSize: 11,
        color: labelColor,
      );
    }
  }

  void _paintSelection(
    Canvas canvas,
    Rect plot,
    List<Offset?> points,
    Size size,
  ) {
    final index = selected;
    if (index == null) return;
    final point = points[index];
    if (point == null) return;

    canvas.drawLine(
      Offset(point.dx, plot.top),
      Offset(point.dx, plot.bottom),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );
    canvas.drawCircle(point, 8, Paint()..color = surfaceColor);
    canvas.drawCircle(
      point,
      6,
      Paint()..color = Mood.colorForAverage(data[index].average!, brightness),
    );

    final day = data[index];
    final label = DateFormat('d/M').format(day.date);
    final value = day.average!.toStringAsFixed(1);
    final painter = _textPainter(
      '$label  •  $value/5',
      fontSize: 12,
      color: tooltipTextColor,
    );
    const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    final boxWidth = painter.width + padding.horizontal;
    final boxHeight = painter.height + padding.vertical;
    final left = (point.dx - boxWidth / 2).clamp(0.0, size.width - boxWidth);
    final top = (point.dy - boxHeight - 14).clamp(0.0, size.height);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, boxWidth, boxHeight),
        const Radius.circular(8),
      ),
      Paint()..color = tooltipColor,
    );
    painter.paint(canvas, Offset(left + padding.left, top + padding.top));
  }

  double _overallAverage() {
    final values = data.map((d) => d.average).whereType<double>().toList();
    if (values.isEmpty) return 3;
    return values.reduce((a, b) => a + b) / values.length;
  }

  TextPainter _textPainter(
    String text, {
    required double fontSize,
    required Color color,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color),
      ),
      textDirection: textDirection,
    )..layout();
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required Color color,
  }) {
    _textPainter(text, fontSize: fontSize, color: color).paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.data != data ||
      old.selected != selected ||
      old.gridColor != gridColor ||
      old.brightness != brightness;
}
