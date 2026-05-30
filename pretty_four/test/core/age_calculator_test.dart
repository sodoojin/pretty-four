import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_four/core/age_calculator.dart';

void main() {
  group('AgeCalculator.toMonths', () {
    test('정확한 개월수 계산', () {
      final birthDate = DateTime(2022, 1, 1);
      final now = DateTime(2026, 5, 1);
      expect(AgeCalculator.toMonths(birthDate, now), 52);
    });

    test('같은 달이면 0개월', () {
      final birthDate = DateTime(2026, 5, 15);
      final now = DateTime(2026, 5, 30);
      expect(AgeCalculator.toMonths(birthDate, now), 0);
    });
  });

  group('AgeCalculator.getCoachingContext', () {
    test('24개월 → 언어 발달 초기 컨텍스트 반환', () {
      final context = AgeCalculator.getCoachingContext(24);
      expect(context, contains('단순하고 일관된 지시'));
    });

    test('60개월 → 자율성 발달 컨텍스트 반환', () {
      final context = AgeCalculator.getCoachingContext(60);
      expect(context, contains('선택지'));
    });

    test('96개월 → 논리적 설명 컨텍스트 반환', () {
      final context = AgeCalculator.getCoachingContext(96);
      expect(context, contains('논리적'));
    });

    test('144개월 → 자율성 존중 컨텍스트 반환', () {
      final context = AgeCalculator.getCoachingContext(144);
      expect(context, contains('자율성'));
    });

    test('48개월 경계: 규칙 이해 컨텍스트 반환', () {
      final context = AgeCalculator.getCoachingContext(48);
      expect(context, contains('선택지'));
    });

    test('84개월 경계: 논리적 설명 컨텍스트 반환', () {
      final context = AgeCalculator.getCoachingContext(84);
      expect(context, contains('논리적'));
    });

    test('132개월 경계: 자율성 컨텍스트 반환', () {
      final context = AgeCalculator.getCoachingContext(132);
      expect(context, contains('자율성'));
    });
  });
}
