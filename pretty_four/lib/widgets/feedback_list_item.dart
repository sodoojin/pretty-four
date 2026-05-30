import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/feedback_item.dart';

class FeedbackListItem extends StatelessWidget {
  final FeedbackItem item;
  const FeedbackListItem({super.key, required this.item});

  String _formatTimestamp(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp row: ⏱ MM:SS
          Row(
            children: [
              const Text(
                '⏱',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                _formatTimestamp(item.timestampSec),
                style: const TextStyle(
                  color: AppColors.blue2,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Original utterance box (soft red)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.softRedBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              item.original,
              style: const TextStyle(
                color: AppColors.softRedText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),

          // Down arrow
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Center(
              child: Text(
                '▾',
                style: TextStyle(
                  color: Color(0xFFC3CCDA),
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Suggestion box (soft green)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.softGreenBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              item.suggestion,
              style: const TextStyle(
                color: AppColors.softGreenText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),

          // Reason (grey italic)
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                item.reason,
                style: const TextStyle(
                  color: AppColors.sub,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
