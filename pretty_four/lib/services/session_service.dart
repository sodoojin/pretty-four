import '../core/api_client.dart';
import '../models/session.dart';

class SessionService {
  Future<List<Session>> getRecentSessions(String childId, {int limit = 20}) async {
    final res = await ApiClient.instance.get('/sessions', queryParameters: {'limit': limit});
    final list = res.data as List;
    return list.map((e) => Session.fromJson(e as Map<String, dynamic>)).toList();
  }
}
