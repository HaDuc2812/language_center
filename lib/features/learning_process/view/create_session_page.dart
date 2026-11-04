import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/view/logout_button.dart';
import '../view_model/learning_process_view_model.dart';

class CreateSessionPage extends ConsumerStatefulWidget {
  const CreateSessionPage({
    required this.classId,
    required this.classCode,
    required this.role,
    super.key,
  });

  final int classId;
  final String classCode;
  final String role;

  @override
  ConsumerState<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends ConsumerState<CreateSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late DateTime _startAt;
  late DateTime _endAt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startAt = DateTime.now();
    _endAt = _startAt.add(const Duration(hours: 2));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = widget.role == 'admin' || widget.role == 'staff';
    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo buổi học • ${widget.classCode}'),
        actions: const [LogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!canCreate)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chỉ admin hoặc nhân viên được tạo buổi học.'),
              ),
            )
          else ...[
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên buổi học',
                  hintText: 'Ví dụ: Buổi 1 - Giới thiệu',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập tên buổi học.'
                    : null,
              ),
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
            const SizedBox(height: 16),
            const Text('Phòng học được lấy theo phòng đã phân công cho lớp.'),
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
                  : const Icon(Icons.add),
              label: const Text('Tạo buổi học'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_endAt.isAfter(_startAt)) {
      setState(() => _error = 'Thời gian kết thúc phải sau thời gian bắt đầu.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final sessionId = await ref
          .read(learningProcessActionsProvider.notifier)
          .createSession(
            classId: widget.classId,
            title: _titleController.text,
            startAt: _startAt,
            endAt: _endAt,
            role: widget.role,
          );
      if (mounted) Navigator.of(context).pop(sessionId);
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
