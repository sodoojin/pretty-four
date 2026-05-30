import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_notifier.dart';
import '../../core/api_error.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/soft_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _auth = AuthService(authNotifier);
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 이메일/비밀번호 공통 입력 검증. 통과하면 true.
  bool _validateInput() {
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (email.isEmpty || pw.isEmpty) {
      _showError('이메일과 비밀번호를 입력해주세요.');
      return false;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showError('올바른 이메일 형식을 입력해주세요.');
      return false;
    }
    if (pw.length < 6) {
      _showError('비밀번호는 6자 이상이어야 해요.');
      return false;
    }
    return true;
  }

  Future<void> _signInWithEmail() async {
    if (!_validateInput()) return;
    setState(() => _loading = true);
    try {
      await _auth.signInWithEmail(_emailCtrl.text.trim(), _pwCtrl.text);
      if (mounted) context.go('/profile-setup');
    } catch (e) {
      _showError('로그인 실패: ${apiErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!_validateInput()) return;
    setState(() => _loading = true);
    try {
      await _auth.signUpWithEmail(_emailCtrl.text.trim(), _pwCtrl.text);
      if (mounted) context.go('/profile-setup');
    } catch (e) {
      _showError('회원가입 실패: ${apiErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithKakao() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithKakao();
      if (mounted) context.go('/profile-setup');
    } catch (e) {
      _showError('카카오 로그인 실패: ${apiErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithGoogle();
      if (mounted) context.go('/profile-setup');
    } catch (e) {
      _showError('구글 로그인 실패: ${apiErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SoftBackground(
        child: Column(
        children: [
          // ── 히어로 (배경은 전체 그라데이션과 통일) ──────────────────
          _AuthHero(),
          // ── 폼 영역 ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 이메일 필드
                  const _FieldLabel('이메일'),
                  const SizedBox(height: 7),
                  _AppTextField(
                    controller: _emailCtrl,
                    hint: 'parent@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 13),
                  // 비밀번호 필드
                  const _FieldLabel('비밀번호'),
                  const SizedBox(height: 7),
                  _AppTextField(
                    controller: _pwCtrl,
                    hint: '••••••••',
                    obscureText: true,
                  ),
                  const SizedBox(height: 18),
                  // 로그인 버튼
                  GradientButton(
                    label: '로그인',
                    onPressed: _loading ? null : _signInWithEmail,
                    loading: _loading,
                  ),
                  const SizedBox(height: 9),
                  // 회원가입 버튼
                  GhostButton(
                    label: '이메일로 회원가입',
                    onPressed: _loading ? null : _signUpWithEmail,
                  ),
                  // 구분선
                  const _OrDivider(),
                  // 카카오 버튼
                  GhostButton(
                    label: '💬  카카오로 시작하기',
                    onPressed: _loading ? null : _signInWithKakao,
                    background: const Color(0xFFFEE500),
                    foreground: const Color(0xFF3A1D1D),
                  ),
                  const SizedBox(height: 9),
                  // 구글 버튼
                  GhostButton(
                    label: '🇬  구글로 시작하기',
                    onPressed: _loading ? null : _signInWithGoogle,
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }
}

// ── 히어로 위젯 ────────────────────────────────────────────────────────────
class _AuthHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          // 콘텐츠 — 브랜드 로고 (배경 블롭은 SoftBackground가 전체에 깔아줌)
          SafeArea(
            bottom: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandLogo(fontSize: 52),
                  const SizedBox(height: 10),
                  Text(
                    '화내지 않고 말하는 법, 같이 연습해요',
                    style: TextStyle(
                      color: AppColors.subStrong.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 필드 라벨 ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.subStrong,
      ),
    );
  }
}

// ── 앱 텍스트 필드 ─────────────────────────────────────────────────────────
class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _AppTextField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.sub, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
      ),
    );
  }
}

// ── 또는 구분선 ────────────────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: AppColors.line, thickness: 1),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '또는',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFAAB3C0),
              ),
            ),
          ),
          Expanded(
            child: Divider(color: AppColors.line, thickness: 1),
          ),
        ],
      ),
    );
  }
}
