import '../core/api_client.dart';
import '../models/child.dart';

class ChildService {
  Future<Child?> getCurrentChild() async {
    try {
      final res = await ApiClient.instance.get('/children/current');
      if (res.data == null) return null;
      return Child.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Child> createChild(String name, DateTime birthDate) async {
    final res = await ApiClient.instance.post('/children', data: {
      'name': name,
      'birthDate': birthDate.toIso8601String().split('T')[0],
    });
    return Child.fromJson(res.data as Map<String, dynamic>);
  }
}
