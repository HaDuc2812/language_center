import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/view/logout_button.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../../core/models/learning_records.dart';
import '../view_model/learning_process_view_model.dart';

class ClassResultsPage extends ConsumerWidget {
  const ClassResultsPage({
    required this.classId,
    required this.classCode,
    required this.classStatus,
    super.key,
  });

  final int classId;
  final String classCode;
  final String classStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(classResultsProvider(classId));
    final role = ref.watch(currentUserRoleProvider).asData?.value ?? 'staff';
    final isSaving = ref.watch(learningProcessActionsProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('Kết quả • $classCode'),
        actions: const [LogoutButton()],
      ),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _Message(text: 'Không tải được kết quả: $error'),
        data: (items) {
          if (items.isEmpty) {
            return const _Message(
              text: 'Lớp chưa có học viên để nhập kết quả.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Kết quả tổng kết (thang điểm 0–10)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final enrollment in items)
                _ResultTile(
                  enrollment: enrollment,
                  classStatus: classStatus,
                  role: role,
                  isSaving: isSaving,
                  onSave: (score, comment, reason) => ref
                      .read(learningProcessActionsProvider.notifier)
                      .saveResult(
                        enrollmentId: enrollment.id,
                        score: score,
                        comment: comment,
                        role: role,
                        correctionReason: reason,
                      ),
                  onDelete: (reason) => ref
                      .read(learningProcessActionsProvider.notifier)
                      .deleteResult(
                        enrollmentId: enrollment.id,
                        role: role,
                        reason: reason,
                      ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.enrollment,
    required this.classStatus,
    required this.role,
    required this.isSaving,
    required this.onSave,
    required this.onDelete,
  });

  final EnrollmentRecord enrollment;
  final String classStatus;
  final String role;
  final bool isSaving;
  final Future<void> Function(double score, String comment, String? reason)
  onSave;
  final Future<void> Function(String reason) onDelete;

  @override
  Widget build(BuildContext context) {
    final score = enrollment.score;
    final canEdit =
        classStatus == 'ongoing' && enrollment.status == 'enrolled' ||
        classStatus == 'completed' && role == 'admin' && score != null;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(score == null ? '—' : score.toStringAsFixed(1)),
        ),
        title: Text(enrollment.studentName),
        subtitle: Text(
          '${enrollment.studentCode} • ${enrollment.status}\n'
          '${score == null
              ? 'Chưa có điểm'
              : score >= 5
              ? 'Đạt'
              : 'Chưa đạt'}'
          '${enrollment.resultComment?.isNotEmpty == true ? ' • ${enrollment.resultComment}' : ''}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          children: [
            IconButton(
              tooltip: score == null ? 'Nhập kết quả' : 'Sửa kết quả',
              onPressed: canEdit && !isSaving ? () => _edit(context) : null,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit_outlined),
            ),
            if (role == 'admin' && score != null)
              IconButton(
                tooltip: 'Xóa kết quả',
                onPressed: isSaving ? null : () => _delete(context),
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final scoreController = TextEditingController(
      text: enrollment.score?.toString() ?? '',
    );
    final commentController = TextEditingController(
      text: enrollment.resultComment ?? '',
    );
    final reasonController = TextEditingController();
    final completed = classStatus == 'completed';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kết quả ${enrollment.studentName}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: scoreController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Điểm (0–10)',
                    hintText: 'Ví dụ: 8.5',
                  ),
                  validator: (value) {
                    final score = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );
                    if (score == null || score < 0 || score > 10) {
                      return 'Nhập điểm hợp lệ từ 0 đến 10.';
                    }
                    final scaledScore = score * 100;
                    if ((scaledScore - scaledScore.round()).abs() > 0.000001) {
                      return 'Điểm chỉ được có tối đa 2 chữ số thập phân.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Nhận xét (tùy chọn)',
                  ),
                  maxLines: 2,
                ),
                if (completed)
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Lý do điều chỉnh bắt buộc',
                    ),
                    validator: (value) =>
                        completed && (value == null || value.trim().isEmpty)
                        ? 'Vui lòng nhập lý do.'
                        : null,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (saved == true) {
      try {
        await onSave(
          double.parse(scoreController.text.trim().replaceAll(',', '.')),
          commentController.text,
          completed ? reasonController.text : null,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã lưu kết quả.')));
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        }
      }
    }

    scoreController.dispose();
    commentController.dispose();
    reasonController.dispose();
  }

  Future<void> _delete(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa kết quả'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Lý do xóa'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập lý do.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
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
    if (confirmed == true) {
      try {
        await onDelete(controller.text.trim());
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa kết quả.')));
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        }
      }
    }
    controller.dispose();
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
