import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../widgets/soft_background.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

/// 하단 탭바 셸 — 홈 / 녹음시작(중앙 강조) / 설정.
/// 홈·설정은 탭으로 전환되고, 녹음시작은 녹음 화면을 push로 띄운다.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SoftBackground(
        child: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x141F2A37),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _sideTab(icon: Icons.home_rounded, label: '홈', index: 0)),
              Expanded(child: _recordTab()),
              Expanded(child: _sideTab(icon: Icons.settings_rounded, label: '설정', index: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sideTab({required IconData icon, required String label, required int index}) {
    final selected = _index == index;
    final color = selected ? AppColors.blue2 : const Color(0xFFAAB3C0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _index = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  /// 중앙 녹음 버튼 — 다른 탭보다 크게 강조(그라데이션 원형).
  Widget _recordTab() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/recording'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.elevated,
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 2),
          const Text('녹음 시작',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue2)),
        ],
      ),
    );
  }
}
