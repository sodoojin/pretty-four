import 'package:flutter/material.dart';
import '../core/theme.dart';

/// 이쁜네살 워드마크 — 손글씨(Gaegu) 핑크 글씨 + 가운데 위 그라데이션 하트.
class BrandLogo extends StatelessWidget {
  final double fontSize;
  final Color textColor;

  /// 단색 모드: 지정 시 글씨·하트를 모두 이 색으로(예: 어두운/컬러 배경 위 흰색).
  /// null이면 글씨=textColor, 하트=민트→블루 그라데이션.
  final Color? monoColor;

  const BrandLogo({
    super.key,
    this.fontSize = 40,
    this.textColor = const Color(0xFFFF8FA3), // 하트 핑크
    this.monoColor,
  });

  @override
  Widget build(BuildContext context) {
    final heartSize = fontSize * 0.42;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 하트 — '네'(가운데) 위쪽. 글자 중앙 기준 살짝 오른쪽으로 보정.
        Padding(
          padding: EdgeInsets.only(
            left: fontSize * 0.30, // '네' 위로 살짝 우측 이동
            bottom: fontSize * 0.02,
          ),
          child: _Heart(size: heartSize, solidColor: monoColor),
        ),
        Text(
          '이쁜네살',
          style: TextStyle(
            fontFamily: 'GaeguLogo',
            fontWeight: FontWeight.w700,
            fontSize: fontSize,
            height: 1.0,
            color: monoColor ?? textColor,
            letterSpacing: fontSize * 0.01,
          ),
        ),
      ],
    );
  }
}

class _Heart extends StatelessWidget {
  final double size;
  final Color? solidColor;
  const _Heart({required this.size, this.solidColor});

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size(size, size * 0.9),
      painter: _HeartPainter(),
    );
    if (solidColor != null) {
      // 단색 하트
      return ShaderMask(
        shaderCallback: (rect) => LinearGradient(
          colors: [solidColor!, solidColor!],
        ).createShader(rect),
        blendMode: BlendMode.srcIn,
        child: paint,
      );
    }
    // 그라데이션 하트
    return ShaderMask(
      shaderCallback: (rect) => AppGradients.primary.createShader(rect),
      blendMode: BlendMode.srcIn,
      child: paint,
    );
  }
}

class _HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Path();
    // 둥근 하트 (손글씨 톤에 맞춘 통통한 형태)
    p.moveTo(w * 0.5, h * 0.30);
    p.cubicTo(w * 0.42, h * 0.06, w * 0.06, h * 0.10, w * 0.06, h * 0.38);
    p.cubicTo(w * 0.06, h * 0.62, w * 0.32, h * 0.78, w * 0.5, h * 0.98);
    p.cubicTo(w * 0.68, h * 0.78, w * 0.94, h * 0.62, w * 0.94, h * 0.38);
    p.cubicTo(w * 0.94, h * 0.10, w * 0.58, h * 0.06, w * 0.5, h * 0.30);
    p.close();
    canvas.drawPath(p, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_HeartPainter old) => false;
}
