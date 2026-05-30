import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_notifier.dart';
import '../../core/theme.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/brand_logo.dart';

/// 인트로(온보딩) — 비 내리는 흐린 유리창이 점점 개면서
/// 감정 스토리텔링(공감→희망)을 전달. 최초 1회만 노출.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  // 비트별 카피
  static const _beats = [
    '육아, 매일이 쉽지 않으시죠',
    '할 일은 많은데,\n아이는 내 맘 같지 않고',
    '화내고 돌아서서 미안했던 적,\n누구나 있어요',
    '발달심리에 기반해,\n아이 나이에 꼭 맞는 코칭을 담았어요',
    '대화를 들려주세요.\n아이 마음에 닿는 말을 함께 찾을게요',
  ];
  // 이 비트부터 비가 갬
  static const _clearFromBeat = 3;

  int _beat = 0;
  Timer? _autoTimer;

  late final AnimationController _rain; // 빗줄기 반복 모션
  late final AnimationController _clear; // 흐림→맑음 전환 (0→1)
  late final AnimationController _logoFade; // 마지막 로고 페이드인

  bool get _isLast => _beat == _beats.length - 1;

  @override
  void initState() {
    super.initState();
    _rain = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _clear = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _logoFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scheduleAuto();
  }

  void _scheduleAuto() {
    _autoTimer?.cancel();
    if (_isLast) return;
    _autoTimer = Timer(const Duration(milliseconds: 3800), _next);
  }

  void _next() {
    if (_isLast) return;
    setState(() => _beat++);
    if (_beat >= _clearFromBeat && !_clear.isCompleted) {
      _clear.forward();
    }
    if (_isLast) {
      _logoFade.forward(); // 마지막 비트 진입 시 로고 페이드인
    }
    _scheduleAuto();
  }

  Future<void> _finish() async {
    _autoTimer?.cancel();
    await authNotifier.markIntroSeen();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _rain.dispose();
    _clear.dispose();
    _logoFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
          animation: Listenable.merge([_rain, _clear]),
          builder: (context, _) {
            final clear = Curves.easeInOut.transform(_clear.value);
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1) 배경 그라데이션: 흐린 블루그레이 → 맑은 민트·블루
                _background(clear),
                // 2) 비 + 성에(fog)
                CustomPaint(
                  painter: _RainPainter(
                    progress: _rain.value,
                    intensity: 1 - clear,
                  ),
                ),
                // 3) 콘텐츠
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                    child: Column(
                      children: [
                        // 건너뛰기
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _finish,
                            child: Text(
                              '건너뛰기',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // 마지막 비트: 이쁜네살 로고 페이드인 (흰색)
                        if (_isLast) ...[
                          FadeTransition(
                            opacity: _logoFade,
                            child: const BrandLogo(
                              fontSize: 50,
                              monoColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],
                        // 카피 (페이드 전환)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, 0.12),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            _beats[_beat],
                            key: ValueKey(_beat),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              height: 1.45,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: Color(0x55000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // 진행 점 인디케이터
                        _dots(),
                        const SizedBox(height: 24),
                        // 시작하기 (마지막 비트에서만)
                        AnimatedOpacity(
                          opacity: _isLast ? 1 : 0,
                          duration: const Duration(milliseconds: 400),
                          child: IgnorePointer(
                            ignoring: !_isLast,
                            child: GradientButton(
                              label: '시작하기',
                              onPressed: _finish,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
    );
  }

  Widget _background(double clear) {
    final top = Color.lerp(const Color(0xFF2B3A4A), AppColors.mint, clear)!;
    final bottom = Color.lerp(const Color(0xFF3C4F63), AppColors.blue, clear)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_beats.length, (i) {
        final on = i == _beat;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: on ? 22 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: on ? 0.95 : 0.4),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}

/// 빗줄기 + 성에(fog) 페인터. intensity 0이면 완전히 갬.
class _RainPainter extends CustomPainter {
  final double progress; // 0..1 반복
  final double intensity; // 0..1 (1=폭우, 0=맑음)
  _RainPainter({required this.progress, required this.intensity});

  // 고정 시드 빗줄기 (Math.random 미사용 — 인덱스 기반 의사난수)
  static const _count = 60;

  double _rand(int i, double salt) {
    final x = math.sin((i + 1) * 12.9898 + salt * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.01) return;

    // 성에(뿌연 흰 막)
    final fog = Paint()..color = Colors.white.withValues(alpha: 0.10 * intensity);
    canvas.drawRect(Offset.zero & size, fog);

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;

    for (var i = 0; i < _count; i++) {
      final speed = 0.6 + _rand(i, 1) * 0.8;
      final len = 14 + _rand(i, 2) * 26;
      final x = _rand(i, 3) * size.width;
      // y 위치: progress * speed 로 흐르고 화면 높이로 wrap
      final cycle = (progress * speed + _rand(i, 4)) % 1.0;
      final y = cycle * (size.height + 60) - 30;
      final opacity = (0.18 + _rand(i, 5) * 0.22) * intensity;
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawLine(Offset(x, y), Offset(x - 2, y + len), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) =>
      old.progress != progress || old.intensity != intensity;
}
