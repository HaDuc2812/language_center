import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/teacher_model.dart';
import '../viewmodels/teacher_action_viewmodel.dart';

/// Màn hình biểu mẫu Thêm mới hoặc Chỉnh sửa hồ sơ giáo viên
class TeacherFormView extends ConsumerStatefulWidget {
  final Teacher? teacher;

  const TeacherFormView({super.key, this.teacher});

  @override
  ConsumerState<TeacherFormView> createState() => _TeacherFormViewState();
}

class _TeacherFormViewState extends ConsumerState<TeacherFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _specialtyInputController;

  late List<String> _specialties;
  String? _specialtiesError;

  bool get isEditMode => widget.teacher != null;

  // Gợi ý các chuyên môn phổ biến tại trung tâm ngoại ngữ
  static const List<String> _commonSpecialties = [
    'IELTS',
    'TOEIC',
    'TOEFL',
    'Giao tiếp',
    'Tiếng Anh Trẻ em',
    'Tiếng Anh Học thuật',
    'Ngữ pháp chuyên sâu',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
    _codeController = TextEditingController(text: t?.code ?? '');
    _nameController = TextEditingController(text: t?.fullName ?? '');
    _emailController = TextEditingController(text: t?.email ?? '');
    _phoneController = TextEditingController(text: t?.phoneNumber ?? '');
    _specialtyInputController = TextEditingController();
    _specialties = t != null ? List<String>.from(t.specialties) : [];
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialtyInputController.dispose();
    super.dispose();
  }

  void _addSpecialty(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    // Tách nếu người dùng paste chuỗi phân cách bởi dấu phẩy
    final parts = trimmed.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);

    setState(() {
      for (final p in parts) {
        if (!_specialties.any((element) => element.toLowerCase() == p.toLowerCase())) {
          _specialties.add(p);
        }
      }
      _specialtiesError = null;
      _specialtyInputController.clear();
    });
  }

  void _removeSpecialty(String item) {
    setState(() {
      _specialties.remove(item);
      if (_specialties.isEmpty) {
        _specialtiesError = 'Vui lòng thêm ít nhất một chuyên môn';
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_specialties.isEmpty) {
      setState(() {
        _specialtiesError = 'Vui lòng thêm ít nhất một chuyên môn';
      });
      return;
    }

    final notifier = ref.read(teacherActionViewModelProvider.notifier);
    bool success = false;

    if (isEditMode) {
      final updatedTeacher = widget.teacher!.copyWith(
        fullName: _nameController.text.trim(),
        specialties: _specialties,
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      success = await notifier.updateTeacher(updatedTeacher);
    } else {
      final newTeacher = Teacher(
        id: '',
        code: _codeController.text.trim().toUpperCase(),
        fullName: _nameController.text.trim(),
        specialties: _specialties,
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        status: TeacherStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      success = await notifier.createTeacher(newTeacher);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Cập nhật giáo viên thành công!'
                : 'Thêm giáo viên mới thành công!',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final actionState = ref.read(teacherActionViewModelProvider);
      final errorMessage = actionState.hasError
          ? actionState.error.toString()
          : 'Đã có lỗi xảy ra. Vui lòng thử lại!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(teacherActionViewModelProvider);
    final isLoading = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Cập nhật giáo viên' : 'Thêm giáo viên mới'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Field: Mã giáo viên (Unique, disabled khi Edit)
                TextFormField(
                  controller: _codeController,
                  enabled: !isEditMode && !isLoading,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Mã giáo viên *',
                    hintText: 'Ví dụ: GV001, ENG01',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    helperText: isEditMode
                        ? 'Mã giáo viên cố định, không thể chỉnh sửa (BR-02)'
                        : 'Mã định danh duy nhất trong toàn hệ thống (BR-01)',
                    filled: isEditMode,
                    fillColor: isEditMode ? Colors.grey.shade100 : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mã giáo viên';
                    }
                    if (value.trim().length < 3) {
                      return 'Mã giáo viên phải có ít nhất 3 ký tự';
                    }
                    if (value.contains(' ')) {
                      return 'Mã giáo viên không được chứa khoảng trắng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Field: Họ và tên
                TextFormField(
                  controller: _nameController,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên giáo viên *',
                    hintText: 'Ví dụ: Nguyễn Văn A',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    if (value.trim().length < 2) {
                      return 'Họ và tên quá ngắn';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Field: Email
                TextFormField(
                  controller: _emailController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email liên hệ *',
                    hintText: 'giaovien@languagecenter.edu.vn',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập địa chỉ email';
                    }
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Địa chỉ email không đúng định dạng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Field: Số điện thoại
                TextFormField(
                  controller: _phoneController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại *',
                    hintText: 'Ví dụ: 0912345678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    final phoneRegex = RegExp(r'^(0[3|5|7|8|9])[0-9]{8}$');
                    if (!phoneRegex.hasMatch(value.trim())) {
                      return 'Số điện thoại không hợp lệ (10 chữ số, bắt đầu bằng 03/05/07/08/09)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Section: Chuyên môn (Specialties)
                Text(
                  'Chuyên môn giảng dạy *',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _specialtyInputController,
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          hintText: 'Nhập chuyên môn (VD: IELTS 7.0+)...',
                          prefixIcon: Icon(Icons.school_outlined),
                          isDense: true,
                        ),
                        onSubmitted: _addSpecialty,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: isLoading
                          ? null
                          : () => _addSpecialty(_specialtyInputController.text),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm'),
                    ),
                  ],
                ),

                if (_specialtiesError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _specialtiesError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Danh sách Chips chuyên môn đã chọn
                if (_specialties.isNotEmpty) ...[
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _specialties.map((s) {
                      return Chip(
                        label: Text(s),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: isLoading ? null : () => _removeSpecialty(s),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.4),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Gợi ý nhanh chuyên môn
                Text(
                  'Gợi ý nhanh:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: _commonSpecialties.map((item) {
                    final isAdded = _specialties.any(
                      (e) => e.toLowerCase() == item.toLowerCase(),
                    );
                    return ActionChip(
                      label: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12,
                          color: isAdded ? Colors.grey : null,
                        ),
                      ),
                      avatar: isAdded
                          ? const Icon(Icons.check, size: 14, color: Colors.green)
                          : const Icon(Icons.add, size: 14),
                      onPressed: (isLoading || isAdded)
                          ? null
                          : () => _addSpecialty(item),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 36),

                // Nút Lưu thông tin
                FilledButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditMode ? 'LƯU THAY ĐỔI' : 'TẠO GIÁO VIÊN',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

