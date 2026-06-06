import '../core/api_client.dart';
import '../models/child.dart';

class ChildService {
  /// 사용자의 아이 목록(생성순).
  Future<List<Child>> getChildren() async {
    final res = await ApiClient.instance.get('/children');
    final list = (res.data as List?) ?? [];
    return list.map((e) => Child.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 활성 아이(없으면 null). 서버 User.activeChildId 기준.
  Future<Child?> getActiveChild() async {
    try {
      final res = await ApiClient.instance.get('/children/active');
      if (res.data == null) return null;
      return Child.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// 하위호환 별칭. 활성 아이를 반환한다.
  Future<Child?> getCurrentChild() => getActiveChild();

  Future<Child> createChild(String name, DateTime birthDate) async {
    final res = await ApiClient.instance.post('/children', data: {
      'name': name,
      'birthDate': birthDate.toIso8601String().split('T')[0],
    });
    return Child.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Child> updateChild(String id, String name, DateTime birthDate) async {
    final res = await ApiClient.instance.patch('/children/$id', data: {
      'name': name,
      'birthDate': birthDate.toIso8601String().split('T')[0],
    });
    return Child.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteChild(String id) async {
    await ApiClient.instance.delete('/children/$id');
  }

  /// 활성 아이 전환(서버 저장).
  Future<Child> setActiveChild(String id) async {
    final res =
        await ApiClient.instance.put('/children/active', data: {'childId': id});
    return Child.fromJson(res.data as Map<String, dynamic>);
  }
}
