import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/child.dart';
import '../../services/child_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/soft_background.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});
  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  final _service = ChildService();
  List<Child> _children = [];
  String? _activeId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final children = await _service.getChildren();
      final active = await _service.getActiveChild();
      if (mounted) {
        setState(() {
          _children = children;
          _activeId = active?.id;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setActive(Child child) async {
    if (child.id == _activeId) return;
    try {
      await _service.setActiveChild(child.id);
      await _load();
    } catch (e) {
      _snack('활성 아이 변경 실패: $e');
    }
  }

  Future<void> _delete(Child child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('아이 삭제'),
        content: Text('${child.name}의 프로필과 모든 분석 기록이 함께 삭제됩니다. 계속할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.softRedText)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteChild(child.id);
      await _load();
    } catch (e) {
      _snack('삭제 실패: $e');
    }
  }

  Future<void> _openForm({Child? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChildForm(service: _service, existing: existing),
    );
    if (saved == true) await _load();
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
            child: const Text('‹',
                style: TextStyle(
                    fontSize: 20,
                    color: AppColors.subStrong,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        title: const Text('아이 관리',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: true,
      ),
      body: SoftBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        children: [
                          if (_children.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text('등록된 아이가 없어요.',
                                    style: TextStyle(color: AppColors.sub)),
                              ),
                            )
                          else
                            ..._children.map(_childCard),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: GradientButton(
                        label: '아이 추가',
                        onPressed: () => _openForm(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _childCard(Child child) {
    final isActive = child.id == _activeId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => _setActive(child),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppGradients.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text('🧸', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(child.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink)),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        const AppPill(
                            label: '활성',
                            background: Color(0xFFD8F3E8),
                            foreground: Color(0xFF1B8A5A)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(DateFormat('yyyy.M.d').format(child.birthDate),
                      style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.subStrong),
              onPressed: () => _openForm(existing: child),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.softRedText),
              onPressed: () => _delete(child),
            ),
          ],
        ),
      ),
    );
  }
}

/// 아이 추가/수정 폼 (바텀시트). 저장 성공 시 true 반환.
class _ChildForm extends StatefulWidget {
  final ChildService service;
  final Child? existing;
  const _ChildForm({required this.service, this.existing});
  @override
  State<_ChildForm> createState() => _ChildFormState();
}

class _ChildFormState extends State<_ChildForm> {
  late final TextEditingController _nameCtrl;
  DateTime? _birthDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _birthDate = widget.existing?.birthDate;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    DateTime temp = _birthDate ?? DateTime(now.year - 3, now.month, now.day);
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, temp),
                  child: const Text('확인',
                      style: TextStyle(
                          color: AppColors.blue2, fontWeight: FontWeight.w800)),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: temp,
                  minimumDate: DateTime(2010, 1, 1),
                  maximumDate: now,
                  onDateTimeChanged: (d) => temp = d,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름과 생년월일을 입력해주세요.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await widget.service.createChild(name, _birthDate!);
      } else {
        await widget.service.updateChild(widget.existing!.id, name, _birthDate!);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.existing == null ? '아이 추가' : '아이 수정',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 18),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: '아이 이름',
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.line, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDate,
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
                    _birthDate == null
                        ? '생년월일 선택'
                        : DateFormat('yyyy년 M월 d일').format(_birthDate!),
                    style: TextStyle(
                        fontSize: 14,
                        color: _birthDate == null ? AppColors.sub : AppColors.ink),
                  ),
                  const Text('📅', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: '저장',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
}
