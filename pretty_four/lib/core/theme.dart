import 'package:flutter/material.dart';

/// 이쁜네살 디자인 시스템 — 소프트 파스텔 · 민트&블루
class AppColors {
  static const mint = Color(0xFF5FE3C4);
  static const mint2 = Color(0xFF3ED0C0);
  static const blue = Color(0xFF6B9DFC);
  static const blue2 = Color(0xFF4F7EF0);

  static const ink = Color(0xFF1F2A37);
  static const sub = Color(0xFF7A8694);
  static const subStrong = Color(0xFF54627A);
  static const line = Color(0xFFEEF1F6);
  static const bg = Color(0xFFF4F7FB);
  static const card = Color(0xFFFFFFFF);

  static const softRedBg = Color(0xFFFFF1F0);
  static const softRedText = Color(0xFF9B3A2C);
  static const softGreenBg = Color(0xFFEAF8F1);
  static const softGreenText = Color(0xFF1E7A52);

  static const chipOrangeBg = Color(0xFFFFF4E8);
  static const chipOrangeText = Color(0xFFD98324);
  static const chipBlueBg = Color(0xFFEEF3FF);
}

class AppGradients {
  /// 메인 그라데이션 (민트 → 블루)
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.mint, AppColors.blue],
  );

  /// 연한 파스텔 배경 그라데이션
  static const soft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEAFBF6), Color(0xFFEEF3FF)],
  );
}

class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x381F2A37), // rgba(31,42,55,.22)
      blurRadius: 18,
      offset: Offset(0, 6),
      spreadRadius: -10,
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: Color(0x474F7EF0), // rgba(79,126,240,.28)
      blurRadius: 30,
      offset: Offset(0, 10),
      spreadRadius: -12,
    ),
  ];
}

class AppRadius {
  static const card = 22.0;
  static const cta = 26.0;
  static const button = 18.0;
  static const input = 16.0;
  static const pill = 999.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue2,
      surface: AppColors.bg,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.ink,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
