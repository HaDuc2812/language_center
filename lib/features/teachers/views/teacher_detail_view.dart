import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/teacher_model.dart';
import '../viewmodels/teacher_action_viewmodel.dart';
import 'teacher_form_view.dart';

/// Màn hình xem chi tiết hồ sơ giáo viên và thực hiện các hành động nhanh (Sửa, Đổi trạng thái, Xóa)
class TeacherDetailView extends ConsumerWidget {
  final String teacherId;

  const TeacherDetailView({super.key, required this.teacherId});

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _confirmToggleStatus(
    BuildContext context,
    WidgetRef ref,
    Teacher teacher,
  ) {
    final isCurrentlyActive = teacher.isActive;
    final targetAction = isCurrentlyActive ? 'ngưng hoạt động' : 'kích hoạt lại';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Xác nhận $targetAction'),
          content: Text(
            isCurrentlyActive
                ? 'Bạn có chắc chắn muốn ngưng hoạt động giáo viên "${teacher.fullName}" (${teacher.code})? '
                    'Hệ thống sẽ kiểm tra xem giáo viên có đang phụ trách lớp học nào (Planned, Open, Ongoing) hay không.'
                : 'Bạn có chắc chắn muốn kích hoạt lại giáo viên "${teacher.fullName}" (${teacher.code}) để phân công lớp?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final notifier =
                    ref.read(teacherActionViewModelProvider.notifier);
                final success = await notifier.toggleTeacherStatus(
                  teacher.id,
                  teacher.status,
                );

                if (!context.mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isCurrentlyActive
                            ? 'Đã chuyển giáo viên sang trạng thái Ngưng hoạt động.'
                            : 'Đã kích hoạt lại giáo viên thành công.',
                      ),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  final actionState =
                      ref.read(teacherActionViewModelProvider);
                  final msg = actionState.hasError
                      ? actionState.error.toString()
                      : 'Không thể thay đổi trạng thái giáo viên.';

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Teacher teacher,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 36),
          title: const Text('Xóa hồ sơ giáo viên'),
          content: Text(
            'Hành động này sẽ xóa vĩnh viễn giáo viên "${teacher.fullName}" (${teacher.code}).\n\n'
            'LƯU Ý: Nếu giáo viên đã từng được phân công vào bất kỳ lớp học nào, hệ thống sẽ chặn xóa để bảo toàn dữ liệu (BR-03).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final notifier =
                    ref.read(teacherActionViewModelProvider.notifier);
                final success = await notifier.deleteTeacher(teacher.id);

                if (!context.mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã xóa giáo viên "${teacher.fullName}" thành công.',
                      ),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context).pop(); // Trở về danh sách
                } else {
                  final actionState =
                      ref.read(teacherActionViewModelProvider);
                  final msg = actionState.hasError
                      ? actionState.error.toString()
                      : 'Không thể xóa giáo viên.';

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 6),
                    ),
                  );
                }
              },
              child: const Text('Xóa vĩnh viễn'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherAsync = ref.watch(teacherDetailStreamProvider(teacherId));
    final actionState = ref.watch(teacherActionViewModelProvider);
    final isActionLoading = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết giáo viên'),
        actions: [
          if (teacherAsync.hasValue && teacherAsync.value != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Chỉnh sửa hồ sơ',
              onPressed: isActionLoading
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeacherFormView(
                            teacher: teacherAsync.value!,
                          ),
                        ),
                      );
                    },
            ),
          ],
        ],
      ),
      body: teacherAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Không thể tải thông tin giáo viên',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        data: (teacher) {
          if (teacher == null) {
            return const Center(
              child: Text('Giáo viên không tồn tại hoặc đã bị xóa.'),
            );
          }

          final isActive = teacher.isActive;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Profile Card
                Card(
                  elevation: 0,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: isActive
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey.shade300,
                          child: Text(
                            teacher.fullName.isNotEmpty
                                ? teacher.fullName
                                    .trim()
                                    .split(' ')
                                    .last[0]
                                    .toUpperCase()
                                : 'GV',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teacher.fullName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      teacher.code,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isActive
                                            ? Colors.green.shade300
                                            : Colors.red.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      teacher.status.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isActive
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card: Thông tin liên hệ
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin liên hệ',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Email'),
                          subtitle: Text(
                            teacher.email.isNotEmpty
                                ? teacher.email
                                : 'Chưa cập nhật',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.phone_outlined),
                          title: const Text('Số điện thoại'),
                          subtitle: Text(
                            teacher.phoneNumber.isNotEmpty
                                ? teacher.phoneNumber
                                : 'Chưa cập nhật',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card: Chuyên môn giảng dạy
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chuyên môn giảng dạy',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        if (teacher.specialties.isEmpty)
                          const Text(
                            'Chưa cập nhật chuyên môn nào.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 6.0,
                            children: teacher.specialties.map((s) {
                              return Chip(
                                label: Text(s),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.3),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card: Thông tin hệ thống
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin hệ thống',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ngày tạo hồ sơ:',
                                style: TextStyle(color: Colors.grey)),
                            Text(_formatDateTime(teacher.createdAt)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cập nhật gần nhất:',
                                style: TextStyle(color: Colors.grey)),
                            Text(_formatDateTime(teacher.updatedAt)),
                          ],
                        ),
                        if (teacher.accountUid != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Liên kết UID Auth:',
                                  style: TextStyle(color: Colors.grey)),
                              Text(teacher.accountUid!),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Bottom Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isActionLoading
                            ? null
                            : () => _confirmToggleStatus(
                                  context,
                                  ref,
                                  teacher,
                                ),
                        icon: Icon(
                          isActive ? Icons.block : Icons.check_circle_outline,
                          color: isActive ? Colors.orange : Colors.green,
                        ),
                        label: Text(
                          isActive ? 'Ngưng HĐ' : 'Kích hoạt',
                          style: TextStyle(
                            color: isActive ? Colors.orange : Colors.green,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: isActionLoading
                            ? null
                            : () => _confirmDelete(
                                  context,
                                  ref,
                                  teacher,
                                ),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text(
                          'Xóa giáo viên',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.red.shade50,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

