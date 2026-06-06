import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_four/models/child.dart';

void main() {
  group('Child.fromJson', () {
    test('단일 아이 camelCase 응답을 파싱', () {
      final json = {
        'id': 'c1',
        'userId': 'u1',
        'name': '첫째',
        'birthDate': '2021-05-01',
        'createdAt': '2026-05-31T09:00:00.000Z',
      };
      final child = Child.fromJson(json);
      expect(child.id, 'c1');
      expect(child.userId, 'u1');
      expect(child.name, '첫째');
      expect(child.birthDate, DateTime.parse('2021-05-01'));
    });

    test('GET /children 목록(2명)을 파싱', () {
      final list = [
        {
          'id': 'c1',
          'userId': 'u1',
          'name': '첫째',
          'birthDate': '2020-03-01',
          'createdAt': '2026-05-31T09:00:00.000Z',
        },
        {
          'id': 'c2',
          'userId': 'u1',
          'name': '둘째',
          'birthDate': '2022-07-01',
          'createdAt': '2026-05-31T10:00:00.000Z',
        },
      ];
      final children =
          list.map((e) => Child.fromJson(e as Map<String, dynamic>)).toList();
      expect(children, hasLength(2));
      expect(children.map((c) => c.name).toList(), ['첫째', '둘째']);
      expect(children[1].id, 'c2');
    });
  });
}
