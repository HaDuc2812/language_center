import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/learning_records.dart';
import '../view_model/course_view_model.dart';

class ClassFormPage extends ConsumerStatefulWidget {
  const ClassFormPage({this.studyClass, super.key});

  /// null = tạo mới, != null = sửa
  final ClassRecord? studyClass;

  @override
  ConsumerState<ClassFormPage> createState() => _ClassFormPageState();
}

class _ClassFormPageState extends ConsumerState<ClassFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late final TextEditingController _scheduleController;

  int? _selectedCourseId;
  int? _selectedTeacherId;
  int? _selectedRoomId;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.studyClass != null;

  @override
  void initState() {
    super.initState();
    final c = widget.studyClass;
    _codeController = TextEditingController(text: c?.code ?? '');
    _nameController = TextEditingController(text: c?.name ?? '');
    _capacityController = TextEditingController(
      text: c?.capacity.toString() ?? '',
    );
    _scheduleController = TextEditingController(text: c?.scheduleDetails ?? '');
    _startDate = c?.startDate ?? DateTime.now();
    _endDate = c?.endDate ?? DateTime.now().add(const Duration(days: 90));
    _selectedCourseId = c?.courseId;
    _selectedTeacherId = c?.teacherId;
    _selectedRoomId = c?.roomId;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _capacityController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu dropdown
    final courses = ref.watch(courseListProvider);
    final teachers = ref.watch(activeTeacherListProvider);
    final classrooms = ref.watch(classroomListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Sửa lớp học' : 'Tạo lớp học')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Mã lớp (không sửa khi edit) ──
            TextFormField(
              controller: _codeController,
              enabled: !_isEditing,
              decoration: const InputDecoration(
                labelText: 'Mã lớp *',
                hintText: 'VD: IELTS50_01',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),

            // ── Tên lớp ──
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên lớp *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),

            // ── Dropdown chọn khóa học ──
            courses.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Lỗi tải khóa học: $e'),
              data: (items) {
                final active = items
                    .where(
                      (c) => c.status == 'active' || c.id == _selectedCourseId,
                    )
                    .toList();
                return DropdownButtonFormField<int>(
                  initialValue: _selectedCourseId,
                  decoration: const InputDecoration(
                    labelText: 'Khóa học *',
                    border: OutlineInputBorder(),
                  ),
                  items: active
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.courseCode} — ${c.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: _isEditing
                      ? null // không đổi khóa học khi sửa
                      : (v) => setState(() => _selectedCourseId = v),
                  validator: (v) => v == null ? 'Chọn khóa học' : null,
                );
              },
            ),
            const SizedBox(height: 12),

            // ── Dropdown chọn giáo viên ──
            teachers.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Lỗi tải giáo viên: $e'),
              data: (items) => DropdownButtonFormField<int>(
                initialValue: _selectedTeacherId,
                decoration: const InputDecoration(
                  labelText: 'Giáo viên *',
                  border: OutlineInputBorder(),
                ),
                items: items
                    .map(
                      (t) => DropdownMenuItem(
                        value: t['id'] as int,
                        child: Text(
                          '${t['teacher_code']} — ${t['full_name']}'
                          '${t['status'] == 'active' ? '' : ' (ngưng)'}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedTeacherId = v),
                validator: (v) => v == null ? 'Chọn giáo viên' : null,
              ),
            ),
            const SizedBox(height: 12),

            // ── Dropdown chọn phòng ──
            classrooms.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Lỗi tải phòng: $e'),
              data: (items) {
                final active = items
                    .where(
                      (r) => r.status == 'active' || r.id == _selectedRoomId,
                    )
                    .toList();
                return DropdownButtonFormField<int>(
                  initialValue: _selectedRoomId,
                  decoration: const InputDecoration(
                    labelText: 'Phòng học *',
                    border: OutlineInputBorder(),
                  ),
                  items: active
                      .map(
                        (r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(
                            '${r.roomCode} — ${r.roomName} (${r.capacity} chỗ)',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRoomId = v),
                  validator: (v) => v == null ? 'Chọn phòng' : null,
                );
              },
            ),
            const SizedBox(height: 12),

            // ── Sĩ số tối đa ──
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Sĩ số tối đa *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return 'Phải > 0';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ── Ngày bắt đầu / kết thúc ──
            _DateTile(
              title: 'Ngày bắt đầu',
              value: _startDate,
              onPick: (v) => setState(() => _startDate = v),
            ),
            const SizedBox(height: 8),
            _DateTile(
              title: 'Ngày kết thúc',
              value: _endDate,
              onPick: (v) => setState(() => _endDate = v),
            ),
            const SizedBox(height: 12),

            // ── Lịch học mô tả ──
            TextFormField(
              controller: _scheduleController,
              decoration: const InputDecoration(
                labelText: 'Lịch học',
                hintText: 'VD: Thứ 2 - 4 - 6 (18:00 - 20:00)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

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
              label: Text(_isEditing ? 'Cập nhật' : 'Tạo lớp học'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_endDate.isAfter(_startDate)) {
      setState(() => _error = 'Ngày kết thúc phải sau ngày bắt đầu.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final actions = ref.read(courseActionsProvider.notifier);
      if (_isEditing) {
        await actions.updateStudyClass(
          id: widget.studyClass!.id,
          name: _nameController.text,
          teacherId: _selectedTeacherId!,
          roomId: _selectedRoomId!,
          maxCapacity: int.parse(_capacityController.text.trim()),
          startDate: _startDate,
          endDate: _endDate,
          scheduleDetails: _scheduleController.text,
        );
      } else {
        await actions.createStudyClass(
          classCode: _codeController.text,
          name: _nameController.text,
          courseId: _selectedCourseId!,
          teacherId: _selectedTeacherId!,
          roomId: _selectedRoomId!,
          maxCapacity: int.parse(_capacityController.text.trim()),
          startDate: _startDate,
          endDate: _endDate,
          scheduleDetails: _scheduleController.text,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Đã cập nhật lớp.' : 'Đã tạo lớp học.'),
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
}

/// Widget chọn ngày đơn giản
class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.title,
    required this.value,
    required this.onPick,
  });
  final String title;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(title),
      subtitle: Text(
        '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}',
      ),
      trailing: const Icon(Icons.edit_calendar_outlined),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) onPick(date);
      },
    ),
  );
}
