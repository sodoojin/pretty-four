import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_notifier.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/child_service.dart';
import '../../models/child.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _childService = ChildService();
  Child? _child;

  @override
  void initState() {
    super.initState();
    _loadChild();
  }

  Future<void> _loadChild() async {
    final child = await _childService.getCurrentChild();
    if (mounted) setState(() => _child = child);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('로그아웃')),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService(authNotifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 4, 2, 18),
              child: Text('설정',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ),

            // 아이 프로필 카드
            _profileCard(),
            const SizedBox(height: 20),

            // 메뉴
            _menuGroup([
              _menuItem(
                emoji: '🧸',
                label: '아이 관리',
                sub: '아이 추가·전환·수정·삭제',
                onTap: () async {
                  await context.push('/children');
                  _loadChild();
                },
              ),
              _menuItem(
                emoji: '🕑',
                label: '전체 기록',
                sub: '지난 대화 분석을 모두 확인',
                onTap: () => context.push('/history'),
              ),
            ]),
            const SizedBox(height: 12),
            _menuGroup([
              _menuItem(
                emoji: '🚪',
                label: '로그아웃',
                onTap: _logout,
                danger: true,
              ),
            ]),

            const SizedBox(height: 24),
            const Center(
              child: Text('이쁜네살 v1.0.0',
                  style: TextStyle(fontSize: 12, color: AppColors.sub)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.soft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text('🧸', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _child?.name ?? '아이 정보',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 3),
                const Text('우리 아이 코칭 프로필',
                    style: TextStyle(fontSize: 12, color: AppColors.subStrong)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem({
    required String emoji,
    required String label,
    String? sub,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 19)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: danger ? AppColors.softRedText : AppColors.ink)),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(sub,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.sub)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC3CCDA)),
            ],
          ),
        ),
      ),
    );
  }
}
