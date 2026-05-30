import 'package:flutter/material.dart';
import '../core/theme.dart';

class WaveformWidget extends StatelessWidget {
  final List<double> amplitudes;
  final Color color;

  const WaveformWidget({
    super.key,
    required this.amplitudes,
    this.color = AppColors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformPainter(amplitudes: amplitudes),
      child: const SizedBox(height: 80, width: double.infinity),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;

  _WaveformPainter({required this.amplitudes});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final barWidth = size.width / amplitudes.length;

    for (int i = 0; i < amplitudes.length; i++) {
      final barHeight = (amplitudes[i] * size.height).clamp(4.0, size.height);
      final x = i * barWidth + barWidth / 2;
      final top = size.height / 2 - barHeight / 2;
      final bottom = size.height / 2 + barHeight / 2;

      // Lerp horizontally from mint to blue across the bar array
      final t = amplitudes.length > 1 ? i / (amplitudes.length - 1) : 0.0;
      final barColor = Color.lerp(AppColors.mint, AppColors.blue, t)!;

      final paint = Paint()
        ..color = barColor
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.amplitudes != amplitudes;
}
