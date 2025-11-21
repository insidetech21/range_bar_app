// lib/widgets/range_bar.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models.dart';

class RangeBar extends StatelessWidget {
  final TestCaseModel testCase;
  final double value; // current input value
  final double height;

  const RangeBar({super.key, required this.testCase, required this.value, this.height = 28});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        height: max(80, height + 40),
        child: CustomPaint(
          painter: _RangeBarPainter(testCase: testCase, value: value, height: height),
          size: Size(constraints.maxWidth, max(80, height + 40)),
        ),
      );
    });
  }
}

class _RangeBarPainter extends CustomPainter {
  final TestCaseModel testCase;
  final double value;
  final double height;

  _RangeBarPainter({required this.testCase, required this.value, required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 8;
    final double rightPadding = 8;
    final double barTop = 16;
    final double barHeight = height;
    final double barLeft = leftPadding;
    final double barRight = size.width - rightPadding;
    final double barWidth = max(1, barRight - barLeft);

    final rrect = RRect.fromLTRBR(barLeft, barTop, barRight, barTop + barHeight, Radius.circular(barHeight / 2));
    final basePaint = Paint()..color = Colors.grey.shade300;
    canvas.drawRRect(rrect, basePaint);

    // --- REPLACE the current cursor-based loop with this ---
    final totalSpan = testCase.max - testCase.min;
    if (totalSpan <= 0) return;

// draw each section at correct absolute position (left computed from start)
    for (final s in testCase.sections) {
      final sectionSpan = (s.end - s.start).clamp(0.0, totalSpan);
      final leftPos = barLeft + ((s.start - testCase.min) / totalSpan) * barWidth;
      final w = (sectionSpan / totalSpan) * barWidth;

      // skip zero-width segments defensively
      if (w <= 0.0) continue;

      final rect = RRect.fromLTRBR(leftPos, barTop, leftPos + w, barTop + barHeight, Radius.circular(8));
      final paint = Paint()..color = s.color;
      canvas.drawRRect(rect, paint);
    }


    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final s in testCase.sections) {
      final pos = barLeft + ((s.start - testCase.min) / totalSpan) * barWidth;
      canvas.drawLine(Offset(pos, barTop + barHeight), Offset(pos, barTop + barHeight + 6), Paint()..color = Colors.black);
      final label = s.start.toStringAsFixed(s.start.truncateToDouble() == s.start ? 0 : 1);
      textPainter.text = TextSpan(text: label, style: TextStyle(color: Colors.black, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos - textPainter.width / 2, barTop + barHeight + 8));
    }

    final lastPos = barLeft + ((testCase.max - testCase.min) / totalSpan) * barWidth;
    canvas.drawLine(Offset(lastPos, barTop + barHeight), Offset(lastPos, barTop + barHeight + 6), Paint()..color = Colors.black);
    textPainter.text = TextSpan(text: testCase.max.toStringAsFixed(0), style: TextStyle(color: Colors.black, fontSize: 10));
    textPainter.layout();
    textPainter.paint(canvas, Offset(lastPos - textPainter.width / 2, barTop + barHeight + 8));

    if (!value.isNaN) {
      final clamped = value.clamp(testCase.min, testCase.max);
      final markerX = barLeft + ((clamped - testCase.min) / totalSpan) * barWidth;
      final markerTop = barTop + barHeight + 16;
      final path = Path();
      final markerSize = 10.0;
      path.moveTo(markerX - markerSize, markerTop + markerSize);
      path.lineTo(markerX + markerSize, markerTop + markerSize);
      path.lineTo(markerX, markerTop);
      path.close();
      canvas.drawPath(path, Paint()..color = Colors.black);

      textPainter.text = TextSpan(text: value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1), style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold));
      textPainter.layout();
      textPainter.paint(canvas, Offset(markerX - textPainter.width / 2, markerTop + markerSize + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _RangeBarPainter oldDelegate) {
    return oldDelegate.testCase != testCase || oldDelegate.value != value;
  }
}
