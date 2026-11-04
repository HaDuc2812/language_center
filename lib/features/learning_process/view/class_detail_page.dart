import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/view/logout_button.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../../core/models/learning_records.dart';
import '../view_model/learning_process_view_model.dart';
import 'attendance_page.dart';
import 'class_results_page.dart';
import 'create_session_page.dart';
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
    final role = ref.watch(currentUserRoleProvider).asData?.value;

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
            children: [
              if (currentClass.status == 'ongoing' &&
                  (role == 'admin' || role == 'staff'))
                OutlinedButton.icon(
                  onPressed: () => _createSession(role!),
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

  Future<void> _createSession(String role) async {
    final sessionId = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => CreateSessionPage(
          classId: widget.learningClass.id,
          classCode: widget.learningClass.code,
          role: role,
        ),
      ),
    );
    if (sessionId != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã tạo buổi học cho lớp.')));
    }
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}
