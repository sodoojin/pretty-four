import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../core/theme.dart';
import 'app_widgets.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;

  const SessionCard({super.key, required this.session, required this.onTap});

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return m > 0 ? '$m분 $s초' : '$s초';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final date = DateFormat('M월 d일').format(local);
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    return '$date · $ampm $displayHour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            // 둥근 아이콘 박스 (soft gradient)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppGradients.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text('🎙️', style: TextStyle(fontSize: 19)),
            ),
            const SizedBox(width: 13),
            // 날짜 + 서브텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(session.recordedAt),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '녹음 ${_formatDuration(session.durationSec)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.sub,
                    ),
                  ),
                ],
              ),
            ),
            // 화살표
            const Text(
              '›',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFFC3CCDA),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
