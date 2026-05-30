import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class RecordingService {
  final _recorder = AudioRecorder();
  DateTime? _startTime;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> start(String sessionId) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$sessionId.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
    _startTime = DateTime.now();
    return path;
  }

  Future<String?> stop() async => await _recorder.stop();

  Future<void> pause() async => await _recorder.pause();

  Future<void> resume() async => await _recorder.resume();

  Stream<Amplitude> get amplitudeStream =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  int get elapsedSeconds =>
      _startTime == null ? 0 : DateTime.now().difference(_startTime!).inSeconds;

  Future<bool> get isRecording => _recorder.isRecording();

  Future<void> dispose() => _recorder.dispose();
}
