import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student.dart';
import '../view_model/student_view_model.dart';
import 'student_form_page.dart';

class StudentDetailPage extends ConsumerWidget {
  const StudentDetailPage({required this.studentId, super.key});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));
    final actionState = ref.watch(studentActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết học viên'),
        actions: [
          studentAsync.whenOrNull(
                data: (student) => student == null
                    ? null
                    : IconButton(
                        tooltip: 'Chỉnh sửa',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                StudentFormPage(editStudent: student),
                          ),
                        ),
                      ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: studentAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Không tải được thông tin: $error'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(studentDetailProvider(studentId)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Học viên không tồn tại.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Avatar + name card ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Text(
                          student.fullName.isNotEmpty
                              ? student.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName,
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student.code,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            _StatusBadge(status: student.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Info card ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Số điện thoại',
                        value: student.phone.isNotEmpty
                            ? student.phone
                            : '(chưa cập nhật)',
                      ),
                      const Divider(indent: 56),
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: student.email.isNotEmpty
                            ? student.email
                            : '(chưa cập nhật)',
                      ),
                      const Divider(indent: 56),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Ngày tạo',
                        value: _formatDate(student.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Quick status change & Actions (SRS UC06, UC10) ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: actionState.isLoading
                              ? null
                              : () => _showChangeStatusDialog(context, ref, student),
                          icon: const Icon(Icons.sync_alt_outlined),
                          label: const Text('Đổi trạng thái'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Associated Class Enrollments (SRS UC07) ──
              Text(
                'Lớp học đã đăng ký',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ref.watch(studentEnrollmentsProvider(student.id)).when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => Text('Không tải được lớp: $error'),
                    data: (enrollments) {
                      if (enrollments.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Học viên chưa đăng ký lớp học nào.'),
                          ),
                        );
                      }
                      return Card(
                        child: Column(
                          children: [
                            for (final e in enrollments)
                              ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.class_outlined),
                                ),
                                title: Text(
                                  '${e['class_code']} — ${e['class_name']}',
                                ),
                                subtitle: Text(
                                  'Khóa: ${e['course_name']}\n'
                                  'Trạng thái: ${e['enrollment_status']} • Lớp: ${e['class_status']}'
                                  '${e['score'] != null ? ' • Điểm: ${e['score']}' : ''}',
                                ),
                                isThreeLine: true,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              const SizedBox(height: 20),

              // ── Danger zone (SRS UC06) ──
              Card(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hành động nguy hiểm',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onPressed: actionState.isLoading
                              ? null
                              : () => _confirmDelete(context, ref, student),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Xóa học viên'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showChangeStatusDialog(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    String selectedStatus = student.status;
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Đổi trạng thái học viên'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Chọn trạng thái mới',
              border: OutlineInputBorder(),
            ),
            items: Student.validStatuses.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(Student.statusLabel[s] ?? s),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) selectedStatus = val;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selectedStatus),
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != null && confirmed != student.status) {
      try {
        await ref.read(studentActionsProvider.notifier).changeStatus(
              id: student.id,
              newStatus: confirmed,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã đổi trạng thái sang "${Student.statusLabel[confirmed]}".',
              ),
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa học viên'),
        content: Text(
          'Bạn có chắc muốn xóa học viên "${student.fullName}" '
          '(${student.code})?\n\n'
          'Học viên chỉ có thể bị xóa nếu chưa từng có lượt đăng ký học nào.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(studentActionsProvider.notifier)
          .deleteStudent(student.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa học viên ${student.fullName}.')),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (context.mounted) {
        // Offer deactivation if deletion was blocked by existing history
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Không thể xóa'),
            content: Text(
              '$error\n\nBạn có muốn chuyển trạng thái học viên này sang "Ngưng hoạt động" (inactive) không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ref
                        .read(studentActionsProvider.notifier)
                        .changeStatus(
                          id: student.id,
                          newStatus: 'inactive',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã chuyển học viên sang Ngưng hoạt động.'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
                child: const Text('Ngưng hoạt động'),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  Color _color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      'studying' || 'active' => cs.primary,
      'graduated' => Colors.green.shade700,
      _ => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        Student.statusLabel[status] ?? status,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: const TextStyle(fontSize: 12)),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }
}
