import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student.dart';
import '../view_model/student_view_model.dart';

/// Used for both Add and Edit.
/// Pass [editStudent] to edit an existing student; leave null to add new.
class StudentFormPage extends ConsumerStatefulWidget {
  const StudentFormPage({this.editStudent, super.key});

  final Student? editStudent;

  @override
  ConsumerState<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends ConsumerState<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late String _status;
  bool _codeLoading = false;

  bool get _isEdit => widget.editStudent != null;

  @override
  void initState() {
    super.initState();
    final s = widget.editStudent;
    _codeController = TextEditingController(text: s?.code ?? '');
    _nameController = TextEditingController(text: s?.fullName ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _status = s?.status ?? 'studying';

    // Auto-generate code when adding
    if (!_isEdit) _loadNextCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadNextCode() async {
    setState(() => _codeLoading = true);
    try {
      final code = await ref.read(nextStudentCodeProvider.future);
      if (mounted) _codeController.text = code;
    } catch (_) {
      // non-critical — user can type manually
    } finally {
      if (mounted) setState(() => _codeLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(studentActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Chỉnh sửa học viên' : 'Thêm học viên'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Mã học viên ──────────────────────────────────────
            TextFormField(
              controller: _codeController,
              enabled: !_isEdit && !actionState.isLoading,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Mã học viên *',
                hintText: 'VD: STU0001',
                helperText: _isEdit
                    ? 'Mã học viên cố định, không thể thay đổi.'
                    : null,
                prefixIcon: const Icon(Icons.badge_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: _codeLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mã học viên.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Họ tên ───────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              enabled: !actionState.isLoading,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Họ và tên *',
                hintText: 'Nguyễn Văn A',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập họ và tên.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Số điện thoại ─────────────────────────────────────
            TextFormField(
              controller: _phoneController,
              enabled: !actionState.isLoading,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                hintText: '0901234567',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isNotEmpty &&
                    !RegExp(r'^[0-9+\-\s]{7,15}$').hasMatch(v)) {
                  return 'Số điện thoại không hợp lệ.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Email ─────────────────────────────────────────────
            TextFormField(
              controller: _emailController,
              enabled: !actionState.isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'example@email.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isNotEmpty &&
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                  return 'Email không hợp lệ.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Trạng thái ────────────────────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Trạng thái *',
                prefixIcon: Icon(Icons.flag_outlined),
                border: OutlineInputBorder(),
              ),
              items: Student.validStatuses.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(Student.statusLabel[s] ?? s),
                );
              }).toList(),
              onChanged: actionState.isLoading
                  ? null
                  : (value) => setState(() => _status = value ?? 'studying'),
            ),
            const SizedBox(height: 28),

            // ── Submit ────────────────────────────────────────────
            FilledButton.icon(
              onPressed: actionState.isLoading ? null : _submit,
              icon: actionState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_isEdit ? Icons.save_outlined : Icons.person_add_outlined),
              label: Text(_isEdit ? 'Lưu thay đổi' : 'Thêm học viên'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_isEdit) {
        await ref.read(studentActionsProvider.notifier).updateStudent(
          id: widget.editStudent!.id,
          code: _codeController.text,
          fullName: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          status: _status,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật thông tin học viên.')),
          );
          Navigator.of(context).pop();
        }
      } else {
        await ref.read(studentActionsProvider.notifier).addStudent(
          code: _codeController.text,
          fullName: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          status: _status,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã thêm học viên ${_nameController.text.trim()}.',
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}
