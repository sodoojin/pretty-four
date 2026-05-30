import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/analysis_service.dart';
import '../../services/child_service.dart';
import '../../core/theme.dart';

class ProcessingScreen extends StatefulWidget {
  final String sessionId;
  const ProcessingScreen({super.key, required this.sessionId});
  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  final _analysisService = AnalysisService();
  final _childService = ChildService();
  Timer? _pollTimer;
  int _elapsedSeconds = 0;
  Timer? _clockTimer;
  String _statusMessage = '대화를 분석하고 있어요...';
  bool _uploadStarted = false;

  // Spinner animation
  late final AnimationController _spinController;

  static const _messages = [
    '대화를 분석하고 있어요...',
    '음성을 텍스트로 변환하고 있어요...',
    '훈육 패턴을 파악하고 있어요...',
    '코칭 내용을 준비하고 있어요...',
    '거의 다 됐어요!',
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
          final idx = (_elapsedSeconds ~/ 8).clamp(0, _messages.length - 1);
          _statusMessage = _messages[idx];
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_uploadStarted) {
      _uploadStarted = true;
      _startUploadAndAnalyze();
    }
  }

  Future<void> _startUploadAndAnalyze() async {
    final extra = GoRouterState.of(context).extra;
    final extraMap = extra is Map ? extra : null;
    final audioPath = extraMap?['audioPath'] as String?;
    final durationSec = (extraMap?['durationSec'] as int?) ?? 0;

    if (audioPath == null) {
      _startPolling(widget.sessionId);
      return;
    }

    final file = File(audioPath);
    if (!file.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('녹음 파일을 찾을 수 없어요.')),
        );
        context.go('/home');
      }
      return;
    }

    try {
      final child = await _childService.getCurrentChild();
      if (child == null || !mounted) return;

      final sessionId = await _analysisService.uploadAndTriggerAnalysis(
        childId: child.id,
        audioPath: audioPath,
        durationSec: durationSec,
      );
      _startPolling(sessionId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패: ${e.toString()}')),
        );
        context.go('/home');
      }
    }
  }

  void _startPolling(String sessionId) {
    var isPolling = false;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (isPolling) return;
      isPolling = true;
      _analysisService.pollSession(sessionId).then((session) {
        isPolling = false;
        if (!mounted) return;
        if (session.isCompleted) {
          _pollTimer?.cancel();
          context.pushReplacement('/result/$sessionId');
        } else if (session.isFailed) {
          _pollTimer?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('분석에 실패했어요. 다시 시도해주세요.')),
            );
            context.go('/home');
          }
        }
      }).catchError((e) {
        isPolling = false;
        debugPrint('Polling error: $e');
      });
    });
  }

  // Current step index derived from elapsed seconds (0..4)
  int get _currentStep =>
      (_elapsedSeconds ~/ 8).clamp(0, _messages.length - 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Conic-gradient-style loading ring with 🧠 inside
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _RingPainter(progress: _spinController.value),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: Center(
                          child: Container(
                            width: 74,
                            height: 74,
                            decoration: const BoxDecoration(
                              color: AppColors.bg,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '🧠',
                                style: TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                // Title
                const Text(
                  '대화를 분석하고\n있어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.02 * 22,
                    height: 1.3,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                // Sub text
                const Text(
                  '음성을 텍스트로 변환하고\n훈육 패턴을 파악하는 중이에요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.sub,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                // Step dots
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_messages.length, (i) {
                    final isActive = i == _currentStep;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: isActive ? 22 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.blue
                            : const Color(0xFFD4DDEC),
                        borderRadius: BorderRadius.circular(isActive ? 5 : 50),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 26),
                // Elapsed time + status message
                Text(
                  '$_elapsedSeconds초 경과 · $_statusMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.blue2,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }
}

/// Paints a conic-gradient-style spinning ring (blue → mint arc).
class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const strokeWidth = 5.0;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFFE7EDF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Gradient arc — sweep ~270° and rotate by progress
    final rect = Rect.fromCircle(center: center, radius: radius);
    const sweepAngle = math.pi * 1.5; // 270 degrees
    final startAngle = (progress * 2 * math.pi) - math.pi / 2;

    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: const [AppColors.blue, AppColors.mint, AppColors.blue],
        stops: const [0.0, 0.5, 1.0],
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        tileMode: TileMode.clamp,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
