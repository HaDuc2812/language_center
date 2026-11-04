import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_model/learning_process_view_model.dart';
import 'class_detail_page.dart';

class ClassesPage extends ConsumerStatefulWidget {
  const ClassesPage({super.key});

  @override
  ConsumerState<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends ConsumerState<ClassesPage> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classListProvider);

    return Scaffold(
      body: classes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _ErrorMessage(message: 'Không tải được danh sách lớp: $error'),
        data: (items) {
          final filtered = items.where((item) {
            final query = _searchController.text.trim().toLowerCase();
            return (query.isEmpty ||
                    item.code.toLowerCase().contains(query) ||
                    item.name.toLowerCase().contains(query)) &&
                (_statusFilter == 'all' || item.status == _statusFilter);
          }).toList();
          if (items.isEmpty) {
            return const _EmptyMessage(message: 'Chưa có lớp học nào.');
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Tìm theo mã hoặc tên lớp',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'planned', child: Text('Dự kiến')),
                    DropdownMenuItem(value: 'open', child: Text('Đang mở')),
                    DropdownMenuItem(
                      value: 'ongoing',
                      child: Text('Đang diễn ra'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Hoàn thành'),
                    ),
                    DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                  ],
                  onChanged: (value) => setState(() {
                    _statusFilter = value ?? 'all';
                  }),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Không có lớp phù hợp bộ lọc.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.menu_book_outlined),
                              ),
                              title: Text('${item.code} — ${item.name}'),
                              subtitle: Text(
                                '${item.status} • ${item.courseName}\n'
                                '${item.enrolledCount}/${item.capacity} học viên • '
                                '${item.teacherName} • ${item.roomName}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ClassDetailPage(learningClass: item),
                                ),
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

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
  );
}
