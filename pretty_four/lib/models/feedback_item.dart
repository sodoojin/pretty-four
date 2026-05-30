class FeedbackItem {
  final int timestampSec;
  final String original;
  final String suggestion;
  final String reason;

  const FeedbackItem({
    required this.timestampSec,
    required this.original,
    required this.suggestion,
    required this.reason,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) => FeedbackItem(
        timestampSec: json['timestamp_sec'] as int,
        original: json['original'] as String,
        suggestion: json['suggestion'] as String,
        reason: json['reason'] as String,
      );

  Map<String, dynamic> toJson() => {
        'timestamp_sec': timestampSec,
        'original': original,
        'suggestion': suggestion,
        'reason': reason,
      };
}
