import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../services/recording_service.dart';
import '../../widgets/waveform_widget.dart';
import '../../widgets/app_widgets.dart';
import '../../core/theme.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});
  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final _service = RecordingService();
  final _amplitudes = <double>[];
  StreamSubscription? _ampSub;
  Timer? _timer;
  bool _isRecording = false;
  bool _isPaused = false;
  int _seconds = 0;
  String? _sessionId;
  String? _audioPath;

  // Pulse animation for the red recording dot
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ampSub = _service.amplitudeStream.listen((amp) {
      if (_isRecording && !_isPaused) {
        setState(() {
          // normalize: Amplitude.current is in dBFS (-160 to 0), map to 0..1
          final normalized = ((amp.current + 60) / 60).clamp(0.05, 1.0);
          _amplitudes.add(normalized);
          if (_amplitudes.length > 60) _amplitudes.removeAt(0);
        });
      }
    });
  }

  Future<void> _startRecording() async {
    final granted = await _service.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마이크 권한이 필요합니다.')),
        );
      }
      return;
    }
    _sessionId = const Uuid().v4();
    _audioPath = await _service.start(_sessionId!);
    if (!mounted) return;
    const maxRecordingSeconds = 600; // 10분
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        setState(() => _seconds++);
        if (_seconds >= maxRecordingSeconds) {
          _stopAndAnalyze();
        }
      }
    });
    setState(() => _isRecording = true);
  }

  Future<void> _togglePause() async {
    if (_isPaused) {
      await _service.resume();
    } else {
      await _service.pause();
    }
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _stopAndAnalyze() async {
    _timer?.cancel();
    await _service.stop();
    if (mounted && _sessionId != null) {
      context.pushReplacement(
        '/processing/$_sessionId',
        extra: {'audioPath': _audioPath, 'durationSec': _seconds},
      );
    }
  }

  /// 기기에 저장된 음성 파일을 선택해 분석 흐름으로 진입.
  Future<void> _analyzeSample() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m4a', 'mp3', 'wav', 'aac', 'caf', 'mp4', 'm4b'],
      );
      final path = result?.files.single.path;
      if (path == null) return; // 사용자가 취소함
      if (!mounted) return;
      final sessionId = const Uuid().v4();
      context.pushReplacement(
        '/processing/$sessionId',
        extra: {'audioPath': path, 'durationSec': 0},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 선택 실패: ${e.toString()}')),
        );
      }
    }
  }

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bg, Color(0xFFEAF1FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: AppShadows.card,
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.subStrong,
                          size: 22,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '대화 녹음',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
              ),

              // Main body — centered
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Recording state pill / start section
                    if (_isRecording) ...[
                      // "녹음 중" pill with pulsing red dot
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (context, child) {
                                return Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5A5A),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color.fromRGBO(255, 90, 90, 0.15 * _pulseAnim.value),
                                        blurRadius: 6,
                                        spreadRadius: 6 * _pulseAnim.value,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              '녹음 중',
                              style: TextStyle(
                                color: Color(0xFFFF5A5A),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      // Timer
                      Text(
                        _formatTime(_seconds),
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.02 * 54,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '최대 10분까지 녹음할 수 있어요',
                        style: TextStyle(
                          color: AppColors.sub,
                          fontSize: 13,
                        ),
                      ),
                      // 9분 경고
                      if (_seconds >= 540)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '최대 녹음 시간(10분)에 거의 도달했어요',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      // Waveform
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 34),
                        child: WaveformWidget(amplitudes: _amplitudes),
                      ),
                      // Control buttons: pause (white circle) + stop (gradient circle, larger)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Pause / Resume button — white circle
                          GestureDetector(
                            onTap: _togglePause,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: AppShadows.card,
                              ),
                              child: Icon(
                                _isPaused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                                color: AppColors.subStrong,
                                size: 28,
                              ), // dynamic icon — cannot be const
                            ),
                          ),
                          const SizedBox(width: 22),
                          // Stop / Analyze button — gradient circle, larger
                          GestureDetector(
                            onTap: _stopAndAnalyze,
                            child: Container(
                              width: 74,
                              height: 74,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppGradients.primary,
                                boxShadow: AppShadows.elevated,
                              ),
                              child: const Icon(
                                Icons.stop_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '분석 시작하려면 정지를 누르세요',
                        style: TextStyle(
                          color: AppColors.sub,
                          fontSize: 13,
                        ),
                      ),
                    ] else ...[
                      // Not recording state
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 34),
                        child: WaveformWidget(amplitudes: _amplitudes),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: GradientButton(
                          label: '녹음 시작',
                          onPressed: _startRecording,
                          icon: const Icon(Icons.mic_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: GhostButton(
                            label: '저장된 음성으로 분석',
                            onPressed: _analyzeSample,
                            icon: const Icon(Icons.science_outlined,
                                color: AppColors.blue2, size: 18),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _timer?.cancel();
    _pulseController.dispose();
    _service.dispose();
    super.dispose();
  }
}
