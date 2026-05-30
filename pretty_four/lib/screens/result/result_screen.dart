import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/analysis_result.dart';
import '../../services/analysis_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/soft_background.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/feedback_list_item.dart';

class ResultScreen extends StatefulWidget {
  final String sessionId;
  const ResultScreen({super.key, required this.sessionId});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _service = AnalysisService();
  AnalysisResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    try {
      final result = await _service.getResult(widget.sessionId);
      if (mounted) {
        setState(() {
          _result = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAFBF6),
      appBar: AppBar(
        title: const Text('분석 결과'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          color: AppColors.subStrong,
          onPressed: () => context.pop(),
        ),
      ),
      body: SoftBackground(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.blue2,
                  strokeWidth: 2.4,
                ),
              )
            : _error != null
                ? _buildError(_error!)
                : _result == null
                    ? _buildEmpty()
                    : _buildResult(_result!),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              '오류: $error',
              style: const TextStyle(
                color: AppColors.softRedText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildEmpty() {
    return const Center(
      child: Text(
        '결과를 불러올 수 없어요.',
        style: TextStyle(color: AppColors.sub, fontSize: 14),
      ),
    );
  }

  Widget _buildResult(AnalysisResult result) {
    final ageYears = result.childAgeMonths ~/ 12;
    final ageMonthsRem = result.childAgeMonths % 12;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      children: [
        // Age pill + date row
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 16),
          child: Row(
            children: [
              AppPill(
                label: '만 $ageYears세 $ageMonthsRem개월',
                background: AppColors.chipBlueBg,
                foreground: AppColors.blue2,
              ),
              const SizedBox(width: 10),
              Text(
                DateFormat('yyyy.MM.dd HH:mm').format(result.createdAt.toLocal()),
                style: const TextStyle(
                  color: AppColors.sub,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Summary card
        SummaryCard(summary: result.summary),

        // Feedback section
        if (result.feedbacks.isNotEmpty) ...[
          SectionTitle('시점별 피드백 · ${result.feedbacks.length}건'),
          ...result.feedbacks.map((f) => FeedbackListItem(item: f)),
        ] else ...[
          const SectionTitle('시점별 피드백'),
          const AppCard(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text('🎉', style: TextStyle(fontSize: 32)),
                SizedBox(height: 10),
                Text(
                  '특별히 개선할 발화가 없었어요.',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  '잘하고 계세요!',
                  style: TextStyle(
                    color: AppColors.sub,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
