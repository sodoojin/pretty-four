import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/child_service.dart';
import '../../services/session_service.dart';
import '../../models/child.dart';
import '../../models/session.dart';
import '../../widgets/session_card.dart';
import '../../core/theme.dart';
import '../../widgets/app_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _childService = ChildService();
  final _sessionService = SessionService();
  Child? _child;
  List<Session> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final child = await _childService.getCurrentChild();
      if (!mounted) return;
      if (child == null) {
        context.go('/profile-setup');
        return;
      }
      final sessions =
          await _sessionService.getRecentSessions(child.id, limit: 5);
      if (mounted) {
        setState(() {
          _child = child;
          _sessions = sessions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 커스텀 헤더
                  _buildHeader(),
                  // 스크롤 영역
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 메인 CTA 카드
                          _buildCtaCard(),
                          // 최근 분석
                          const SectionTitle('최근 분석'),
                          if (_sessions.isNotEmpty)
                            ..._sessions.map(
                              (s) => SessionCard(
                                session: s,
                                onTap: () => context.push('/result/${s.id}'),
                              ),
                            )
                          else
                            _buildEmptyState(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '안녕하세요 👋',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.sub,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _child != null ? '${_child!.name}와의 대화' : '이쁜네살',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.01 * 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaCard() {
    return GestureDetector(
      onTap: () => context.push('/recording'),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppRadius.cta),
          boxShadow: AppShadows.elevated,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 마이크 아이콘 박스
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🎙️', style: TextStyle(fontSize: 26)),
                ),
                const SizedBox(height: 14),
                const Text(
                  '대화 녹음 시작',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '아이와의 대화를 들려주세요',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20), // 화살표 공간
              ],
            ),
            // 우하단 화살표
            const Positioned(
              right: 0,
              bottom: 0,
              child: Text(
                '→',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppGradients.soft,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text('📋', style: TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 분석 기록이 없어요.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '첫 대화를 녹음해보세요!',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.sub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
