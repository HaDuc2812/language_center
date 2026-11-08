import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/course_models.dart';
import '../view_model/course_view_model.dart';

class CourseFormPage extends ConsumerStatefulWidget {
  const CourseFormPage({this.course, super.key});

  /// null = tạo mới, != null = sửa
  final CourseRecord? course;

  @override
  ConsumerState<CourseFormPage> createState() => _CourseFormPageState();
}

class _CourseFormPageState extends ConsumerState<CourseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _languageController;
  late final TextEditingController _levelController;
  late final TextEditingController _lessonsController;
  late final TextEditingController _weeksController;
  late String _status;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.course?.courseCode ?? '',
    );
    _nameController = TextEditingController(text: widget.course?.name ?? '');
    _descController = TextEditingController(
      text: widget.course?.description ?? '',
    );
    _languageController = TextEditingController(
      text: widget.course?.language ?? '',
    );
    _levelController = TextEditingController(text: widget.course?.level ?? '');
    _lessonsController = TextEditingController(
      text: widget.course?.plannedLessons.toString() ?? '',
    );
    _weeksController = TextEditingController(
      text: widget.course?.durationWeeks.toString() ?? '',
    );
    _status = widget.course?.status ?? 'active';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _languageController.dispose();
    _levelController.dispose();
    _lessonsController.dispose();
    _weeksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa khóa học' : 'Thêm khóa học'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa khóa học',
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Mã khóa học (không sửa được khi edit)
            TextFormField(
              controller: _codeController,
              enabled: !_isEditing,
              decoration: const InputDecoration(
                labelText: 'Mã khóa học *',
                hintText: 'VD: IELTS_5.0',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên khóa học *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _languageController,
              decoration: const InputDecoration(
                labelText: 'Ngôn ngữ *',
                hintText: 'VD: Tiếng Anh',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _levelController,
              decoration: const InputDecoration(
                labelText: 'Trình độ *',
                hintText: 'VD: 5.0',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lessonsController,
              decoration: const InputDecoration(
                labelText: 'Số buổi dự kiến *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return 'Phải là số > 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weeksController,
              decoration: const InputDecoration(
                labelText: 'Số tuần *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return 'Phải là số > 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (_isEditing)
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Ngưng hoạt động'),
                  ),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'active'),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing ? 'Cập nhật' : 'Tạo khóa học'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final actions = ref.read(courseActionsProvider.notifier);
      if (_isEditing) {
        await actions.updateCourse(
          id: widget.course!.id,
          name: _nameController.text,
          description: _descController.text,
          language: _languageController.text,
          level: _levelController.text,
          plannedLessons: int.parse(_lessonsController.text.trim()),
          durationWeeks: int.parse(_weeksController.text.trim()),
          status: _status,
        );
      } else {
        await actions.createCourse(
          courseCode: _codeController.text,
          name: _nameController.text,
          description: _descController.text,
          language: _languageController.text,
          level: _levelController.text,
          plannedLessons: int.parse(_lessonsController.text.trim()),
          durationWeeks: int.parse(_weeksController.text.trim()),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Đã cập nhật.' : 'Đã tạo khóa học.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khóa học?'),
        content: const Text(
          'Chỉ xóa được nếu khóa học chưa có lớp nào. '
          'Nếu đã có lớp, hãy chuyển sang Ngưng hoạt động.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(courseActionsProvider.notifier)
          .deleteCourse(widget.course!.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa khóa học.')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
