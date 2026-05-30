import 'feedback_item.dart';
import 'conversation_summary.dart';

class AnalysisResult {
  final String id;
  final String sessionId;
  final ConversationSummary summary;
  final List<FeedbackItem> feedbacks;
  final String? rawTranscript;
  final int childAgeMonths;
  final DateTime createdAt;

  const AnalysisResult({
    required this.id,
    required this.sessionId,
    required this.summary,
    required this.feedbacks,
    this.rawTranscript,
    required this.childAgeMonths,
    required this.createdAt,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        summary: ConversationSummary.fromJson(
            json['summary'] as Map<String, dynamic>),
        feedbacks: (json['feedbacks'] as List)
            .map((e) => FeedbackItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        rawTranscript: json['rawTranscript'] as String?,
        childAgeMonths: json['childAgeMonths'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'summary': summary.toJson(),
        'feedbacks': feedbacks.map((e) => e.toJson()).toList(),
        'rawTranscript': rawTranscript,
        'childAgeMonths': childAgeMonths,
        'createdAt': createdAt.toIso8601String(),
      };
}
