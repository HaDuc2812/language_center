import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/view/logout_button.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../../core/models/learning_records.dart';
import '../view_model/learning_process_view_model.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({
    required this.classId,
    required this.classCode,
    required this.classStatus,
    super.key,
  });

  final int classId;
  final String classCode;
  final String classStatus;

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  int? _selectedSessionId;

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(classSessionsProvider(widget.classId));
    final role = ref.watch(currentUserRoleProvider).asData?.value ?? 'staff';

    return Scaffold(
      appBar: AppBar(
        title: Text('Điểm danh • ${widget.classCode}'),
        actions: const [LogoutButton()],
      ),
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _Message(text: 'Không tải được buổi học: $error'),
        data: (items) {
          if (items.isEmpty) {
            return const _Message(
              text:
                  'Lớp chưa có buổi học. Hãy tạo buổi học trước khi điểm danh.',
            );
          }
          final selectedId = items.any((item) => item.id == _selectedSessionId)
              ? _selectedSessionId!
              : items.first.id;
          final selected = items.firstWhere((item) => item.id == selectedId);
          final attendance = ref.watch(sessionAttendanceProvider(selectedId));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<int>(
                  initialValue: selectedId,
                  decoration: const InputDecoration(
                    labelText: 'Chọn buổi học',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final session in items)
                      DropdownMenuItem(
                        value: session.id,
                        child: Text(
                          'Buổi ${session.number} • ${session.title} '
                          '(${_dateTime(session.startAt)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedSessionId = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Trạng thái buổi: ${sessionStatusLabel(selected.status)}',
                  ),
                ),
              ),
              Expanded(
                child: attendance.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      _Message(text: 'Không tải được điểm danh: $error'),
                  data: (rows) {
                    if (rows.isEmpty) {
                      return const _Message(
                        text: 'Không có học viên đủ điều kiện điểm danh.',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: rows.length,
                      itemBuilder: (context, index) => _AttendanceTile(
                        record: rows[index],
                        session: selected,
                        classStatus: widget.classStatus,
                        role: role,
                        onSave: (status, note, correctionReason) async {
                          await ref
                              .read(learningProcessActionsProvider.notifier)
                              .saveAttendance(
                                enrollmentId: rows[index].enrollmentId,
                                sessionId: selectedId,
                                status: status,
                                note: note,
                                role: role,
                                correctionReason: correctionReason,
                              );
                        },
                        onDelete: (reason) => ref
                            .read(learningProcessActionsProvider.notifier)
                            .deleteAttendance(
                              enrollmentId: rows[index].enrollmentId,
                              sessionId: selectedId,
                              role: role,
                              reason: reason,
                            ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String sessionStatusLabel(String status) => switch (status) {
  'planned' => 'Dự kiến',
  'ongoing' => 'Đang diễn ra',
  'completed' => 'Đã kết thúc',
  'cancelled' => 'Đã hủy',
  _ => status,
};

String _dateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

class _AttendanceTile extends StatefulWidget {
  const _AttendanceTile({
    required this.record,
    required this.session,
    required this.classStatus,
    required this.role,
    required this.onSave,
    required this.onDelete,
  });

  final AttendanceRecord record;
  final SessionRecord session;
  final String classStatus;
  final String role;
  final Future<void> Function(String status, String note, String? reason)
  onSave;
  final Future<void> Function(String reason) onDelete;

  @override
  State<_AttendanceTile> createState() => _AttendanceTileState();
}

class _AttendanceTileState extends State<_AttendanceTile> {
  late String _status;
  late final TextEditingController _noteController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.record.status ?? '';
    _noteController = TextEditingController(text: widget.record.note);
  }

  @override
  void didUpdateWidget(covariant _AttendanceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.status != widget.record.status ||
        oldWidget.record.note != widget.record.note) {
      _status = widget.record.status ?? '';
      _noteController.text = widget.record.note;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final started = !widget.session.startAt.isAfter(DateTime.now());
    final completed = widget.classStatus == 'completed';
    final canEdit =
        widget.session.status != 'cancelled' &&
        (completed
            ? widget.role == 'admin' && widget.record.status != null
            : widget.classStatus == 'ongoing' && started);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.record.studentName} (${widget.record.studentCode})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _status.isEmpty ? null : _status,
              decoration: InputDecoration(
                labelText: _status.isEmpty ? 'Chưa ghi nhận' : 'Điểm danh',
              ),
              items: const [
                DropdownMenuItem(value: 'present', child: Text('Có mặt')),
                DropdownMenuItem(value: 'absent', child: Text('Vắng')),
                DropdownMenuItem(value: 'late', child: Text('Đi muộn')),
                DropdownMenuItem(value: 'excused', child: Text('Có phép')),
              ],
              onChanged: canEdit
                  ? (value) => setState(() => _status = value ?? '')
                  : null,
            ),
            TextField(
              controller: _noteController,
              enabled: canEdit,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
              ),
            ),
            if (canEdit)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.record.status != null)
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      child: const Text('Xóa điểm danh'),
                    ),
                  FilledButton.tonal(
                    onPressed: _saving || _status.isEmpty ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.record.status == null ? 'Lưu' : 'Cập nhật',
                          ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.record.status == null
                      ? 'Chưa ghi nhận'
                      : 'Không thể sửa điểm danh ở trạng thái hiện tại.',
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    String? correctionReason;
    if (widget.classStatus == 'completed') {
      correctionReason = await _askCorrectionReason();
      if (correctionReason == null) return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(_status, _noteController.text, correctionReason);
      if (mounted) {
        setState(() => _error = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu điểm danh.')));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final reason = await _askCorrectionReason();
    if (reason == null) return;
    setState(() => _saving = true);
    try {
      await widget.onDelete(reason);
      if (mounted) {
        setState(() {
          _status = '';
          _error = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa điểm danh, trạng thái trở về chưa ghi nhận.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _askCorrectionReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lý do điều chỉnh'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Lý do'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(text)),
  );
}
