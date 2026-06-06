import '../core/api_client.dart';
import '../models/session.dart';

class SessionService {
  /// 활성 아이(childId) 세션만 조회. 백엔드 GET /sessions?childId= 필터 사용.
  Future<List<Session>> getRecentSessions(String childId, {int limit = 20}) async {
    final res = await ApiClient.instance.get(
      '/sessions',
      queryParameters: {'limit': limit, 'childId': childId},
    );
    final list = res.data as List;
    return list.map((e) => Session.fromJson(e as Map<String, dynamic>)).toList();
  }
}
