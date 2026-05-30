import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/session.dart';
import '../models/analysis_result.dart';

class AnalysisService {
  Future<String> uploadAndTriggerAnalysis({
    required String childId,
    required String audioPath,
    required int durationSec,
  }) async {
    final ext = audioPath.contains('.') ? audioPath.split('.').last.toLowerCase() : 'm4a';
    final formData = FormData.fromMap({
      'childId': childId,
      'durationSec': durationSec.toString(),
      'audio': await MultipartFile.fromFile(audioPath, filename: 'recording.$ext'),
    });

    final res = await ApiClient.instance.post('/sessions/upload', data: formData);
    return res.data['session_id'] as String;
  }

  Future<Session> pollSession(String sessionId) async {
    final res = await ApiClient.instance.get('/sessions/$sessionId');
    return Session.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AnalysisResult?> getResult(String sessionId) async {
    try {
      final res = await ApiClient.instance.get('/sessions/$sessionId/result');
      return AnalysisResult.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
