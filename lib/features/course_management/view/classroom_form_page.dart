import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/course_models.dart';
import '../view_model/course_view_model.dart';

class ClassroomFormPage extends ConsumerStatefulWidget {
  const ClassroomFormPage({this.classroom, super.key});
  final ClassroomRecord? classroom;

  @override
  ConsumerState<ClassroomFormPage> createState() => _ClassroomFormPageState();
}

class _ClassroomFormPageState extends ConsumerState<ClassroomFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late String _status;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.classroom != null;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.classroom?.roomCode ?? '',
    );
    _nameController = TextEditingController(
      text: widget.classroom?.roomName ?? '',
    );
    _capacityController = TextEditingController(
      text: widget.classroom?.capacity.toString() ?? '',
    );
    _status = widget.classroom?.status ?? 'active';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa phòng học' : 'Thêm phòng học'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa phòng học',
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codeController,
              enabled: !_isEditing,
              decoration: const InputDecoration(
                labelText: 'Mã phòng *',
                hintText: 'VD: R302',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên phòng *',
                hintText: 'VD: Room 302',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Sức chứa *',
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
                  DropdownMenuItem(value: 'inactive', child: Text('Ngưng')),
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
              label: Text(_isEditing ? 'Cập nhật' : 'Tạo phòng học'),
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
        await actions.updateClassroom(
          id: widget.classroom!.id,
          roomCode: _codeController.text,
          roomName: _nameController.text,
          capacity: int.parse(_capacityController.text.trim()),
          status: _status,
        );
      } else {
        await actions.createClassroom(
          roomCode: _codeController.text,
          roomName: _nameController.text,
          capacity: int.parse(_capacityController.text.trim()),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Đã cập nhật.' : 'Đã tạo phòng.'),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phòng học?'),
        content: const Text(
          'Chỉ xóa được nếu chưa có lớp hoặc buổi học nào dùng phòng này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
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
          .deleteClassroom(widget.classroom!.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa.')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
