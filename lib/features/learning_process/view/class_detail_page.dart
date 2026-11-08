import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/view/logout_button.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../course_management/view/class_form_page.dart';
import '../../course_management/view/lesson_form_page.dart';
import '../../course_management/view_model/course_view_model.dart';
import '../../../core/models/learning_records.dart';
import '../view_model/learning_process_view_model.dart';
import 'attendance_page.dart';
import 'class_results_page.dart';
import 'student_lookup_page.dart';

class ClassDetailPage extends ConsumerStatefulWidget {
  const ClassDetailPage({required this.learningClass, super.key});

  final ClassRecord learningClass;

  @override
  ConsumerState<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends ConsumerState<ClassDetailPage> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final learningClass = widget.learningClass;
    final currentClass =
        ref
            .watch(classListProvider)
            .asData
            ?.value
            .where((item) => item.id == learningClass.id)
            .firstOrNull ??
        learningClass;
    final enrollments = ref.watch(
      classEnrollmentListProvider(learningClass.id),
    );
    final actionState = ref.watch(learningProcessActionsProvider);
    final courseActionState = ref.watch(courseActionsProvider);
    final role = ref.watch(currentUserRoleProvider).asData?.value;
    final lessons = ref.watch(classSessionsProvider(learningClass.id));
    final rooms = ref.watch(classroomListProvider).asData?.value ?? const [];
    final canManage = role == 'admin' || role == 'staff';
    final busy = actionState.isLoading || courseActionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(learningClass.code),
        actions: const [LogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentClass.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Khóa học: ${currentClass.courseName}'),
                  Text('Giáo viên: ${currentClass.teacherName}'),
                  Text('Phòng: ${currentClass.roomName}'),
                  Text('Trạng thái: ${currentClass.status}'),
                  Text(
                    'Sĩ số: ${currentClass.enrolledCount}/${currentClass.capacity}',
                  ),
                  Text('Lịch học: ${currentClass.scheduleDetails}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!const [
                    'completed',
                    'cancelled',
                  ].contains(currentClass.status) &&
                  canManage)
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ClassFormPage(studyClass: currentClass),
                          ),
                        ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Sửa lớp'),
                ),
              if (currentClass.status == 'planned' && canManage)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _changeStatus('open'),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Mở đăng ký'),
                ),
              if (currentClass.status == 'open' && canManage)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _changeStatus('ongoing'),
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: const Text('Bắt đầu lớp'),
                ),
              if (currentClass.status == 'ongoing' && canManage)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _changeStatus('completed'),
                  icon: const Icon(Icons.task_alt),
                  label: const Text('Hoàn thành'),
                ),
              if (const [
                    'planned',
                    'open',
                    'ongoing',
                  ].contains(currentClass.status) &&
                  canManage)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _changeStatus('cancelled'),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Hủy lớp'),
                ),
              if (currentClass.status == 'planned' && canManage)
                OutlinedButton.icon(
                  onPressed: busy ? null : _deleteClass,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa lớp'),
                ),
              if (const [
                    'planned',
                    'open',
                    'ongoing',
                  ].contains(currentClass.status) &&
                  canManage)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _openLesson(role!, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo buổi học'),
                ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AttendancePage(
                      classId: learningClass.id,
                      classCode: learningClass.code,
                      classStatus: learningClass.status,
                    ),
                  ),
                ),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Điểm danh'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ClassResultsPage(
                      classId: learningClass.id,
                      classCode: learningClass.code,
                      classStatus: learningClass.status,
                    ),
                  ),
                ),
                icon: const Icon(Icons.grade_outlined),
                label: const Text('Kết quả'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Buổi học', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          lessons.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) =>
                _MessageCard(message: 'Không tải được buổi học: $error'),
            data: (items) {
              if (items.isEmpty) {
                return const _MessageCard(message: 'Lớp chưa có buổi học.');
              }
              return Card(
                child: Column(
                  children: [
                    for (final lesson in items)
                      ListTile(
                        title: Text('Buổi ${lesson.number} — ${lesson.title}'),
                        subtitle: Text(
                          '${_lessonStatus(lesson.status)} • '
                          '${_formatDateTime(lesson.startAt)} – ${_formatDateTime(lesson.endAt)}\n'
                          '${rooms.where((room) => room.id == lesson.roomId).firstOrNull?.roomName ?? 'Phòng'}',
                        ),
                        isThreeLine: true,
                        trailing: canManage && _lessonHasAction(lesson)
                            ? _LessonActions(
                                lesson: lesson,
                                busy: busy,
                                onMove: () => _openLesson(role!, lesson),
                                onComplete: () => _completeLesson(lesson.id),
                                onCancel: () => _cancelLesson(lesson.id),
                                onDelete: () => _deleteLesson(lesson.id),
                              )
                            : null,
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Học viên đăng ký',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'enrolled', child: Text('Đang học')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                ],
                onChanged: (value) =>
                    setState(() => _statusFilter = value ?? 'all'),
              ),
              IconButton(
                tooltip: 'Thêm học viên',
                onPressed: actionState.isLoading
                    ? null
                    : () => _pickStudent(context),
                icon: const Icon(Icons.person_add_alt_1),
              ),
            ],
          ),
          enrollments.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => _MessageCard(
              message: 'Không tải được danh sách học viên: $error',
            ),
            data: (items) {
              final visible = _statusFilter == 'all'
                  ? items
                  : items
                        .where((item) => item.status == _statusFilter)
                        .toList();
              if (visible.isEmpty) {
                return const _MessageCard(
                  message: 'Không có lượt đăng ký ở trạng thái này.',
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (final enrollment in visible)
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(enrollment.studentName),
                        subtitle: Text(
                          '${enrollment.studentCode} • ${enrollment.status}'
                          '${enrollment.score == null ? '' : ' • Điểm ${enrollment.score}'}',
                        ),
                        trailing: enrollment.status == 'enrolled'
                            ? IconButton(
                                tooltip: 'Hủy đăng ký',
                                onPressed: actionState.isLoading
                                    ? null
                                    : () => _cancel(enrollment),
                                icon: const Icon(Icons.person_remove_outlined),
                              )
                            : null,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => StudentLookupPage(
                              initialStudentId: enrollment.studentId,
                              initialStudentCode: enrollment.studentCode,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openLesson(String role, SessionRecord? lesson) async {
    final sessionId = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => LessonFormPage(
          classId: widget.learningClass.id,
          classCode: widget.learningClass.code,
          role: role,
          lesson: lesson,
        ),
      ),
    );
    if (sessionId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lesson == null ? 'Đã tạo buổi học.' : 'Đã cập nhật buổi học.',
          ),
        ),
      );
    }
  }

  Future<void> _changeStatus(String nextStatus) async {
    String? reason;
    if (nextStatus == 'cancelled') {
      reason = await _askReason('Lý do hủy lớp');
      if (reason == null) return;
    }
    try {
      await ref
          .read(courseActionsProvider.notifier)
          .changeClassStatus(
            id: widget.learningClass.id,
            nextStatus: nextStatus,
            reason: reason,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái lớp.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _deleteClass() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lớp học?'),
        content: const Text(
          'Chỉ xóa được lớp dự kiến, chưa có đăng ký và chưa có buổi học.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(courseActionsProvider.notifier)
          .deleteClass(widget.learningClass.id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _completeLesson(int lessonId) async {
    try {
      await ref.read(courseActionsProvider.notifier).completeLesson(lessonId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _cancelLesson(int lessonId) async {
    final reason = await _askReason('Lý do hủy buổi học');
    if (reason == null) return;
    try {
      await ref
          .read(courseActionsProvider.notifier)
          .cancelLesson(lessonId: lessonId, reason: reason);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _deleteLesson(int lessonId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa buổi học?'),
        content: const Text('Chỉ xóa buổi chưa bắt đầu và chưa có điểm danh.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(courseActionsProvider.notifier).deleteLesson(lessonId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<String?> _askReason(String title) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Lý do'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập lý do.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    final reason = confirmed == true ? controller.text.trim() : null;
    controller.dispose();
    return reason;
  }

  Future<void> _pickStudent(BuildContext context) async {
    final selected = await showModalBottomSheet<StudentRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _StudentPicker(),
    );
    if (selected == null) return;

    try {
      await ref
          .read(learningProcessActionsProvider.notifier)
          .enroll(studentCode: selected.code, classId: widget.learningClass.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selected.fullName} đã được đăng ký.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _cancel(EnrollmentRecord enrollment) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đăng ký'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: 'Lý do hủy'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập lý do.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref
            .read(learningProcessActionsProvider.notifier)
            .cancelEnrollment(
              enrollmentId: enrollment.id,
              reason: reasonController.text,
            );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        }
      }
    }
    reasonController.dispose();
  }
}

class _StudentPicker extends ConsumerStatefulWidget {
  const _StudentPicker();

  @override
  ConsumerState<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends ConsumerState<_StudentPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentSearchProvider(_query));
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              Text(
                'Chọn học viên',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  labelText: 'Tìm theo mã hoặc tên',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              Expanded(
                child: students.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Center(child: Text('Không tải được học viên: $error')),
                  data: (items) {
                    final eligible = items
                        .where(
                          (item) =>
                              item.status == 'studying' ||
                              item.status == 'active',
                        )
                        .toList();
                    if (eligible.isEmpty) {
                      return const Center(
                        child: Text('Không tìm thấy học viên đang học.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: eligible.length,
                      itemBuilder: (context, index) {
                        final item = eligible[index];
                        return ListTile(
                          title: Text(item.fullName),
                          subtitle: Text('${item.code} • ${item.status}'),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonActions extends StatelessWidget {
  const _LessonActions({
    required this.lesson,
    required this.busy,
    required this.onMove,
    required this.onComplete,
    required this.onCancel,
    required this.onDelete,
  });

  final SessionRecord lesson;
  final bool busy;
  final VoidCallback onMove;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final notStarted =
        lesson.status == 'planned' && lesson.startAt.isAfter(now);
    final canComplete =
        const ['planned', 'ongoing'].contains(lesson.status) &&
        !lesson.endAt.isAfter(now);
    return PopupMenuButton<String>(
      enabled: !busy,
      onSelected: (action) {
        switch (action) {
          case 'move':
            onMove();
          case 'complete':
            onComplete();
          case 'cancel':
            onCancel();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        if (notStarted)
          const PopupMenuItem(value: 'move', child: Text('Dời buổi')),
        if (canComplete)
          const PopupMenuItem(value: 'complete', child: Text('Hoàn thành')),
        if (notStarted)
          const PopupMenuItem(value: 'cancel', child: Text('Hủy buổi')),
        if (notStarted)
          const PopupMenuItem(value: 'delete', child: Text('Xóa')),
      ],
    );
  }
}

bool _lessonHasAction(SessionRecord lesson) {
  final now = DateTime.now();
  final notStarted = lesson.status == 'planned' && lesson.startAt.isAfter(now);
  final canComplete =
      const ['planned', 'ongoing'].contains(lesson.status) &&
      !lesson.endAt.isAfter(now);
  return notStarted || canComplete;
}

String _lessonStatus(String status) => switch (status) {
  'planned' => 'Đã xếp',
  'ongoing' => 'Đang diễn ra',
  'completed' => 'Hoàn thành',
  'cancelled' => 'Đã hủy',
  _ => status,
};

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}
