import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/conversation_summary.dart';
import 'app_widgets.dart';

class SummaryCard extends StatelessWidget {
  final ConversationSummary summary;
  const SummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: 📊 대화 요약
          const Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 17)),
              SizedBox(width: 8),
              Text(
                '대화 요약',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.01,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),

          // 대화 분위기
          const Text(
            '대화 분위기',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.subStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.tone,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),

          // 발견된 패턴
          const Text(
            '발견된 패턴',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.subStrong,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: summary.patterns
                .map((p) => AppPill(
                      label: p,
                      background: AppColors.chipOrangeBg,
                      foreground: AppColors.chipOrangeText,
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),

          // 개선 포인트
          const Text(
            '개선 포인트',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.subStrong,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: summary.improvements
                .map((i) => AppPill(
                      label: i,
                      background: AppColors.softGreenBg,
                      foreground: AppColors.softGreenText,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
