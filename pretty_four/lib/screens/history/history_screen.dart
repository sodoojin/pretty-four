import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/child_service.dart';
import '../../services/session_service.dart';
import '../../models/session.dart';
import '../../widgets/session_card.dart';
import '../../widgets/soft_background.dart';
import '../../core/theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _childService = ChildService();
  final _sessionService = SessionService();
  List<Session> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final child = await _childService.getCurrentChild();
      if (!mounted) return;
      if (child == null) {
        setState(() => _loading = false);
        return;
      }
      final sessions =
          await _sessionService.getRecentSessions(child.id, limit: 100);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAFBF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(13),
              boxShadow: AppShadows.card,
            ),
            alignment: Alignment.center,
            child: const Text(
              '‹',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.subStrong,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        title: const Text(
          '전체 기록',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: SoftBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : _sessions.isEmpty
                    ? _buildEmptyState()
                    : _buildSessionList(),
      ),
    );
  }

  Widget _buildSessionList() {
    // 월별 그룹핑
    final Map<String, List<Session>> grouped = {};
    for (final s in _sessions) {
      final local = s.recordedAt.toLocal();
      final key = '${local.year}년 ${local.month}월';
      grouped.putIfAbsent(key, () => []).add(s);
    }

    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: keys.fold<int>(0, (sum, k) => sum + 1 + grouped[k]!.length),
      itemBuilder: (_, i) {
        // 플랫 인덱스를 월 헤더 + 세션으로 매핑
        int cursor = 0;
        for (final key in keys) {
          if (i == cursor) {
            // 월 헤더
            return Padding(
              padding: const EdgeInsets.fromLTRB(2, 16, 2, 9),
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9AA6B5),
                ),
              ),
            );
          }
          cursor++;
          final list = grouped[key]!;
          if (i < cursor + list.length) {
            final session = list[i - cursor];
            return SessionCard(
              session: session,
              onTap: () => context.push('/result/${session.id}'),
            );
          }
          cursor += list.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Text(
        '오류가 발생했어요. 다시 시도해주세요.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.sub,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        '아직 분석 기록이 없어요.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.sub,
        ),
      ),
    );
  }
}
