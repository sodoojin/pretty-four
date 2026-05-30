import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// 화면 전체에 깔리는 부드러운 파스텔 배경 + 흐릿한 블롭(앰비언트).
/// 블롭은 강하게 블러 처리되어 가장자리에서 잘려도 자연스러운 빛번짐처럼 보인다.
class SoftBackground extends StatelessWidget {
  final Widget child;
  const SoftBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 베이스 그라데이션
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.soft),
          ),
        ),
        // 블롭들 (블러된 원) — 화면 전체에 흩뿌림
        _blob(top: -70, right: -60, size: 230, color: AppColors.mint, alpha: 0.28),
        _blob(top: 160, left: -80, size: 180, color: AppColors.blue, alpha: 0.18),
        _blob(bottom: 120, right: -50, size: 200, color: AppColors.mint, alpha: 0.20),
        _blob(bottom: -60, left: 30, size: 160, color: AppColors.blue, alpha: 0.16),
        _blob(top: 360, right: 90, size: 90, color: AppColors.mint, alpha: 0.22),
        // 콘텐츠
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _blob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
    required double alpha,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: alpha),
          ),
        ),
      ),
    );
  }
}
