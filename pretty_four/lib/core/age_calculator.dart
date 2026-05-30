class AgeCalculator {
  static int toMonths(DateTime birthDate, [DateTime? now]) {
    final reference = now ?? DateTime.now();
    return (reference.year - birthDate.year) * 12 +
        (reference.month - birthDate.month);
  }

  static String getCoachingContext(int months) {
    if (months < 48) {
      return '이 나이(만 ${months ~/ 12}세)는 언어 발달 초기로, 단순하고 일관된 지시가 효과적입니다. '
          '짧은 문장을 사용하고 즉각적인 피드백을 주세요.';
    } else if (months < 84) {
      return '이 나이(만 ${months ~/ 12}세)는 규칙 이해와 자율성이 발달하는 시기입니다. '
          '선택지를 제공하고 규칙의 이유를 간단히 설명해주세요.';
    } else if (months < 132) {
      return '이 나이(만 ${months ~/ 12}세)는 논리적 사고가 발달하는 시기입니다. '
          '논리적 설명과 감정 공감을 우선시하세요.';
    } else {
      return '이 나이(만 ${months ~/ 12}세)는 자율성이 중요한 시기입니다. '
          '협상과 타협을 통해 자율성을 존중해주세요.';
    }
  }
}
