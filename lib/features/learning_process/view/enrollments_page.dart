import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_model/learning_process_view_model.dart';

class EnrollmentsPage extends ConsumerWidget {
  const EnrollmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollments = ref.watch(enrollmentListProvider);
    final classes = ref.watch(classListProvider);
    return enrollments.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Không tải được đăng ký: $error'),
        ),
      ),
      data: (items) => classes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Không tải được lớp học: $error'),
          ),
        ),
        data: (classItems) {
          final activeCount = items
              .where((item) => item.status == 'enrolled')
              .length;
          final cancelledCount = items.length - activeCount;
          final openClasses = classItems
              .where(
                (item) => item.status == 'open' || item.status == 'ongoing',
              )
              .length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Tổng quan quá trình học',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              const Text('Theo dõi đăng ký, sĩ số và tiến độ lớp học.'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    label: 'Lượt đang học',
                    value: '$activeCount',
                    icon: Icons.school_outlined,
                  ),
                  _SummaryCard(
                    label: 'Lượt đã hủy',
                    value: '$cancelledCount',
                    icon: Icons.event_busy_outlined,
                  ),
                  _SummaryCard(
                    label: 'Lớp đang nhận học viên',
                    value: '$openClasses',
                    icon: Icons.class_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Đăng ký gần đây',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Chưa có lượt đăng ký. Mở tab Lớp học để bắt đầu.',
                    ),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (final enrollment in items.take(10))
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(enrollment.studentName),
                          subtitle: Text(
                            '${enrollment.studentCode} • ${enrollment.classCode} '
                            '• ${enrollment.status}',
                          ),
                          trailing: enrollment.score == null
                              ? const Text('Chưa có điểm')
                              : Text(
                                  '${enrollment.score} '
                                  '• ${enrollment.score! >= 5 ? 'Đạt' : 'Chưa đạt'}',
                                ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
