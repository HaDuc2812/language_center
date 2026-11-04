import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_model/learning_process_view_model.dart';

class StudentLookupPage extends ConsumerStatefulWidget {
  const StudentLookupPage({
    this.initialStudentId,
    this.initialStudentCode,
    super.key,
  });

  final int? initialStudentId;
  final String? initialStudentCode;

  @override
  ConsumerState<StudentLookupPage> createState() => _StudentLookupPageState();
}

class _StudentLookupPageState extends ConsumerState<StudentLookupPage> {
  late final TextEditingController _searchController;
  late String _query;
  int? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _query = widget.initialStudentCode ?? '';
    _searchController = TextEditingController(text: _query);
    _selectedStudentId = widget.initialStudentId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentSearchProvider(_query));
    final history = _selectedStudentId == null
        ? null
        : ref.watch(studentHistoryProvider(_selectedStudentId!));

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) => setState(() {
              _query = value.trim();
              _selectedStudentId = null;
            }),
            decoration: InputDecoration(
              labelText: 'Tìm theo mã hoặc tên học viên',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => setState(() {
                  _query = _searchController.text.trim();
                  _selectedStudentId = null;
                }),
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_query.isNotEmpty)
            students.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) =>
                  _InfoCard(message: 'Không thể tìm học viên: $error'),
              data: (items) {
                if (items.isEmpty) {
                  return const _InfoCard(message: 'Không tìm thấy học viên.');
                }
                return Card(
                  child: Column(
                    children: [
                      for (final item in items)
                        ListTile(
                          selected: _selectedStudentId == item.id,
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(item.fullName),
                          subtitle: Text(
                            '${item.code} • ${item.status} • ${item.phone}',
                          ),
                          onTap: () => setState(() {
                            _selectedStudentId = item.id;
                            _searchController.text = item.code;
                            _query = item.code;
                          }),
                        ),
                    ],
                  ),
                );
              },
            ),
          if (_selectedStudentId != null) ...[
            const SizedBox(height: 16),
            Text(
              'Lịch sử học tập',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            history!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  _InfoCard(message: 'Không tải được lịch sử: $error'),
              data: (items) {
                if (items.isEmpty) {
                  return const _InfoCard(
                    message: 'Học viên chưa có lượt đăng ký nào.',
                  );
                }
                return Column(
                  children: [
                    for (final historyItem in items)
                      Card(
                        child: ExpansionTile(
                          title: Text(
                            '${historyItem.enrollment.classCode} — '
                            '${historyItem.enrollment.className}',
                          ),
                          subtitle: Text(
                            'Đăng ký: ${historyItem.enrollment.status} • '
                            '${_date(historyItem.enrollment.enrolledAt)}',
                          ),
                          trailing: historyItem.enrollment.score == null
                              ? const Text('Chưa có điểm')
                              : Text(
                                  '${historyItem.enrollment.score} • '
                                  '${historyItem.enrollment.score! >= 5 ? 'Đạt' : 'Chưa đạt'}',
                                ),
                          children: [
                            if (historyItem.enrollment.cancelReason != null)
                              ListTile(
                                title: const Text('Lý do hủy'),
                                subtitle: Text(
                                  historyItem.enrollment.cancelReason!,
                                ),
                              ),
                            if (historyItem
                                    .enrollment
                                    .resultComment
                                    ?.isNotEmpty ??
                                false)
                              ListTile(
                                title: const Text('Nhận xét kết quả'),
                                subtitle: Text(
                                  historyItem.enrollment.resultComment!,
                                ),
                              ),
                            if (historyItem.attendances.isEmpty)
                              const ListTile(
                                title: Text('Chưa có lịch sử điểm danh.'),
                              )
                            else
                              for (final attendance in historyItem.attendances)
                                ListTile(
                                  title: Text(attendance.sessionTitle),
                                  subtitle: Text(
                                    '${attendance.status}'
                                    '${attendance.note.isEmpty ? '' : ' • ${attendance.note}'}',
                                  ),
                                ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}
