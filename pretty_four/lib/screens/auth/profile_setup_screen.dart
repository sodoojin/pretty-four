import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/child_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/soft_background.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _childService = ChildService();
  final _nameCtrl = TextEditingController();
  DateTime? _birthDate;
  bool _loading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름과 생년월일을 입력해주세요.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _childService.createChild(_nameCtrl.text.trim(), _birthDate!);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SoftBackground(
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 상단 일러스트 + 타이틀 ────────────────────────────
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    // 일러스트 박스 (soft gradient)
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: AppGradients.soft,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🧸',
                          style: TextStyle(fontSize: 46)),
                    ),
                    const SizedBox(height: 18),
                    // 큰 타이틀
                    const Text(
                      '아이에 대해\n알려주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.3,
                        letterSpacing: -0.02 * 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 안내문
                    const Text(
                      '나이에 맞는 코칭을 위해 필요해요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.sub,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ── 아이 이름 필드 ────────────────────────────────────
              const _FieldLabel('아이 이름'),
              const SizedBox(height: 7),
              _AppTextField(
                controller: _nameCtrl,
                hint: '지우',
              ),
              const SizedBox(height: 13),
              // ── 생년월일 선택 ─────────────────────────────────────
              const _FieldLabel('생년월일'),
              const SizedBox(height: 7),
              _DatePickerField(
                birthDate: _birthDate,
                onTap: _pickDate,
              ),
              const SizedBox(height: 32),
              // ── 시작하기 버튼 ─────────────────────────────────────
              GradientButton(
                label: '시작하기',
                onPressed: _loading ? null : _save,
                loading: _loading,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
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

// ── 텍스트 입력 필드 ───────────────────────────────────────────────────────
class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _AppTextField({
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.ink),
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

// ── 생년월일 선택 필드 ────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final DateTime? birthDate;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.birthDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = birthDate == null
        ? '날짜를 선택해주세요'
        : DateFormat('yyyy년 M월 d일').format(birthDate!);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: birthDate == null ? AppColors.sub : AppColors.ink,
              ),
            ),
            const Text(
              '📅',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
