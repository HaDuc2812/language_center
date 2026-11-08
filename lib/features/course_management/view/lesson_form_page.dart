import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/learning_records.dart';
import '../view_model/course_view_model.dart';

class LessonFormPage extends ConsumerStatefulWidget {
  const LessonFormPage({
    required this.classId,
    required this.classCode,
    required this.role,
    this.lesson,
    super.key,
  });

  final int classId;
  final String classCode;
  final String role;
  final SessionRecord? lesson;

  @override
  ConsumerState<LessonFormPage> createState() => _LessonFormPageState();
}

class _LessonFormPageState extends ConsumerState<LessonFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late DateTime _startAt;
  late DateTime _endAt;
  int? _roomId;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    _titleController = TextEditingController(text: lesson?.title ?? '');
    _startAt = lesson?.startAt ?? DateTime.now().add(const Duration(hours: 1));
    _endAt = lesson?.endAt ?? _startAt.add(const Duration(hours: 2));
    _roomId = lesson?.roomId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(classroomListProvider);
    final canEdit = widget.role == 'admin' || widget.role == 'staff';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Dời buổi học • ${widget.classCode}'
              : 'Tạo buổi học • ${widget.classCode}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!canEdit)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chỉ admin hoặc nhân viên được xếp lịch.'),
              ),
            )
          else
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tên buổi học *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập tên buổi học.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  rooms.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text('Lỗi tải phòng: $error'),
                    data: (items) {
                      final active = items
                          .where(
                            (room) =>
                                room.status == 'active' || room.id == _roomId,
                          )
                          .toList();
                      return DropdownButtonFormField<int>(
                        initialValue: _roomId,
                        decoration: const InputDecoration(
                          labelText: 'Phòng học *',
                          border: OutlineInputBorder(),
                        ),
                        items: active
                            .map(
                              (room) => DropdownMenuItem(
                                value: room.id,
                                child: Text(
                                  '${room.roomCode} — ${room.roomName} (${room.capacity} chỗ)',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _roomId = value),
                        validator: (value) =>
                            value == null ? 'Chọn phòng' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _DateTimeTile(
                    title: 'Bắt đầu',
                    value: _startAt,
                    onPick: (value) => setState(() => _startAt = value),
                  ),
                  const SizedBox(height: 8),
                  _DateTimeTile(
                    title: 'Kết thúc',
                    value: _endAt,
                    onPick: (value) => setState(() => _endAt = value),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
                    label: Text(
                      _isEditing ? 'Cập nhật buổi học' : 'Tạo buổi học',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roomId == null) {
      setState(() => _error = 'Chọn phòng học.');
      return;
    }
    if (!_endAt.isAfter(_startAt)) {
      setState(() => _error = 'Thời gian kết thúc phải sau thời gian bắt đầu.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final lessonId = await ref
          .read(courseActionsProvider.notifier)
          .saveLesson(
            lessonId: widget.lesson?.id,
            classId: widget.classId,
            roomId: _roomId!,
            title: _titleController.text,
            startAt: _startAt,
            endAt: _endAt,
            role: widget.role,
          );
      if (mounted) Navigator.of(context).pop(lessonId);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
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
      subtitle: Text(_formatDateTime(value)),
      trailing: const Icon(Icons.edit_calendar_outlined),
      onTap: () => _selectDateTime(context),
    ),
  );

  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null) return;
    onPick(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year} '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
