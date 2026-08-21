import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:airri_mobile/domain/irrigation/entities.dart';
import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

const _chartHeight = 170.0;
const _leftAxisWidth = 34.0;
const _bottomAxisHeight = 18.0;
const _topPadding = 10.0;

// Pilih subset indeks yang diberi label sumbu-x, supaya tidak menumpuk
// saat datanya banyak (periode 30 hari / semua). Titik pertama &
// terakhir selalu ikut dilabeli.
List<int> _labelIndices(int count) {
  if (count <= 7) return List.generate(count, (i) => i);
  const maxLabels = 6;
  final step = (count - 1) / (maxLabels - 1);
  return List.generate(maxLabels, (i) => (i * step).round())
      .toSet()
      .toList()
    ..sort();
}

String _xLabel(
  DateTime date,
  int count,
  String localeName,
  StatsGranularity granularity,
) {
  return switch (granularity) {
    StatsGranularity.day => count <= 7
        ? DateFormat('EEE', localeName).format(date)
        : DateFormat('d/M', localeName).format(date),
    StatsGranularity.week => DateFormat('d/M', localeName).format(date),
    StatsGranularity.month => DateFormat('MMM yy', localeName).format(date),
  };
}

({double min, double max}) _niceBounds(double dataMin, double dataMax) {
  if (dataMax <= dataMin) {
    return (min: (dataMin - 5).clamp(0, double.infinity), max: dataMax + 5);
  }
  final range = dataMax - dataMin;
  final step = range / 4;
  final niceStep = step <= 0 ? 1.0 : (step / 5).ceil() * 5;
  final min = (dataMin / niceStep).floor() * niceStep;
  final max = (dataMax / niceStep).ceil() * niceStep;
  return (min: min.toDouble(), max: (max == min ? min + niceStep : max).toDouble());
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _chartHeight,
      child: Center(
        child: Text(message,
            style: const TextStyle(fontSize: 12, color: IrrigationColors.ink500)),
      ),
    );
  }
}

class SoilMoistureLineChart extends StatelessWidget {
  final List<DailyStat> data;
  final String localeName;
  final StatsGranularity granularity;
  final String emptyMessage;

  const SoilMoistureLineChart({
    super.key,
    required this.data,
    required this.localeName,
    required this.granularity,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _EmptyChart(message: emptyMessage);
    return SizedBox(
      height: _chartHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(
            data: data, localeName: localeName, granularity: granularity),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<DailyStat> data;
  final String localeName;
  final StatsGranularity granularity;

  _LineChartPainter({
    required this.data,
    required this.localeName,
    required this.granularity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartRight = size.width;
    final chartBottom = size.height - _bottomAxisHeight;
    final chartLeft = _leftAxisWidth;
    final chartTop = _topPadding;
    final chartWidth = chartRight - chartLeft;

    final values = data.map((d) => d.avgSoilMoisture).toList();
    final bounds = _niceBounds(
        values.reduce((a, b) => a < b ? a : b), values.reduce((a, b) => a > b ? a : b));

    double yFor(double v) {
      final t = (v - bounds.min) / (bounds.max - bounds.min);
      return chartBottom - t * (chartBottom - chartTop);
    }

    double xFor(int i) => data.length == 1
        ? chartLeft + chartWidth / 2
        : chartLeft + (i / (data.length - 1)) * chartWidth;

    final gridPaint = Paint()
      ..color = IrrigationColors.line100
      ..strokeWidth = 1;
    final labelStyle = const TextStyle(fontSize: 9.5, color: IrrigationColors.ink500);

    for (final v in [bounds.min, (bounds.min + bounds.max) / 2, bounds.max]) {
      final y = yFor(v);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: '${v.toStringAsFixed(0)}%', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartLeft - 6 - tp.width, y - tp.height / 2));
    }

    final linePaint = Paint()
      ..color = IrrigationColors.green600
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final p = Offset(xFor(i), yFor(data[i].avgSoilMoisture));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Emphasize the most recent point.
    final lastPoint = Offset(xFor(data.length - 1), yFor(data.last.avgSoilMoisture));
    canvas.drawCircle(lastPoint, 4, Paint()..color = IrrigationColors.green600);
    canvas.drawCircle(lastPoint, 4, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    for (final i in _labelIndices(data.length)) {
      final tp = TextPainter(
        text: TextSpan(
            text: _xLabel(data[i].date, data.length, localeName, granularity),
            style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xFor(i) - tp.width / 2, chartBottom + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

class WaterUsageBarChart extends StatelessWidget {
  final List<DailyStat> data;
  final String localeName;
  final StatsGranularity granularity;
  final String emptyMessage;

  const WaterUsageBarChart({
    super.key,
    required this.data,
    required this.localeName,
    required this.granularity,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _EmptyChart(message: emptyMessage);
    return SizedBox(
      height: _chartHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarChartPainter(
            data: data, localeName: localeName, granularity: granularity),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<DailyStat> data;
  final String localeName;
  final StatsGranularity granularity;

  _BarChartPainter({
    required this.data,
    required this.localeName,
    required this.granularity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartRight = size.width;
    final chartBottom = size.height - _bottomAxisHeight;
    final chartLeft = _leftAxisWidth;
    final chartTop = _topPadding;
    final chartWidth = chartRight - chartLeft;

    final maxValue = data.map((d) => d.totalWaterMl).reduce((a, b) => a > b ? a : b);
    final niceMax = maxValue <= 0 ? 100.0 : (maxValue / 5).ceil() * 5.0;

    double yFor(double v) {
      final t = v / niceMax;
      return chartBottom - t * (chartBottom - chartTop);
    }

    final gridPaint = Paint()
      ..color = IrrigationColors.line100
      ..strokeWidth = 1;
    final labelStyle = const TextStyle(fontSize: 9.5, color: IrrigationColors.ink500);

    for (final v in [0.0, niceMax / 2, niceMax]) {
      final y = yFor(v);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: v.toStringAsFixed(0), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartLeft - 6 - tp.width, y - tp.height / 2));
    }

    final slot = chartWidth / data.length;
    final barWidth = (slot * 0.5).clamp(4.0, 22.0);
    final barPaint = Paint()..color = IrrigationColors.green600;

    for (var i = 0; i < data.length; i++) {
      final centerX = chartLeft + slot * i + slot / 2;
      final top = yFor(data[i].totalWaterMl);
      final rect = Rect.fromLTRB(
          centerX - barWidth / 2, top, centerX + barWidth / 2, chartBottom);
      final rrect = RRect.fromRectAndCorners(rect,
          topLeft: const Radius.circular(3), topRight: const Radius.circular(3));
      canvas.drawRRect(rrect, barPaint);

      if (_labelIndices(data.length).contains(i)) {
        final tp = TextPainter(
          text: TextSpan(
              text: _xLabel(data[i].date, data.length, localeName, granularity),
            style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(centerX - tp.width / 2, chartBottom + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => oldDelegate.data != data;
}
