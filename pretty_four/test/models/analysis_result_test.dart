import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_four/models/analysis_result.dart';
import 'package:pretty_four/models/feedback_item.dart';
import 'package:pretty_four/models/conversation_summary.dart';

void main() {
  group('FeedbackItem.fromJson', () {
    test('JSON에서 올바르게 파싱', () {
      final json = {
        'timestamp_sec': 42,
        'original': '하지 말라고 했잖아!',
        'suggestion': '지금 힘들구나. 같이 해결해볼까?',
        'reason': '감정 반영 후 대안 제시가 효과적입니다.',
      };
      final item = FeedbackItem.fromJson(json);
      expect(item.timestampSec, 42);
      expect(item.original, '하지 말라고 했잖아!');
      expect(item.suggestion, '지금 힘들구나. 같이 해결해볼까?');
    });
  });

  group('ConversationSummary.fromJson', () {
    test('JSON에서 올바르게 파싱', () {
      final json = {
        'tone': '지시적',
        'patterns': ['명령형 발화 다수', '칭찬 부족'],
        'improvements': ['감정 반영 먼저', '선택지 제공'],
      };
      final summary = ConversationSummary.fromJson(json);
      expect(summary.tone, '지시적');
      expect(summary.patterns.length, 2);
      expect(summary.improvements, contains('감정 반영 먼저'));
    });
  });

  group('AnalysisResult.fromJson', () {
    test('전체 DB 행에서 올바르게 파싱', () {
      final row = {
        'id': 'test-id',
        'sessionId': 'session-id',
        'summary': {
          'tone': '협력적',
          'patterns': ['칭찬 적절'],
          'improvements': [],
        },
        'feedbacks': [
          {
            'timestamp_sec': 10,
            'original': '잘했어',
            'suggestion': '정말 잘했어, 네가 노력했구나!',
            'reason': '구체적 칭찬이 더 효과적입니다.',
          }
        ],
        'rawTranscript': '10초: 잘했어',
        'childAgeMonths': 52,
        'createdAt': '2026-05-30T10:00:00Z',
      };
      final result = AnalysisResult.fromJson(row);
      expect(result.feedbacks.length, 1);
      expect(result.childAgeMonths, 52);
      expect(result.summary.tone, '협력적');
    });
  });
}
