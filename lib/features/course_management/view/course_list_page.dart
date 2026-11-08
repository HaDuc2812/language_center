import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/course_models.dart';
import '../view_model/course_view_model.dart';
import 'course_form_page.dart';

class CourseListPage extends ConsumerStatefulWidget {
  const CourseListPage({super.key});

  @override
  ConsumerState<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends ConsumerState<CourseListPage> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(courseListProvider);

    return Scaffold(
      body: courses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Lỗi: $error')),
        data: (items) {
          final filtered = items.where((item) {
            final query = _searchController.text.trim().toLowerCase();
            return (query.isEmpty ||
                    item.courseCode.toLowerCase().contains(query) ||
                    item.name.toLowerCase().contains(query)) &&
                (_statusFilter == 'all' || item.status == _statusFilter);
          }).toList();

          return Column(
            children: [
              // Thanh tìm kiếm
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Tìm theo mã hoặc tên khóa học',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              // Bộ lọc trạng thái
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Đang hoạt động'),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Ngưng hoạt động'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _statusFilter = value ?? 'all'),
                ),
              ),
              // Danh sách
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Không có khóa học phù hợp.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: item.status == 'active'
                                    ? Colors.green.shade100
                                    : Colors.grey.shade300,
                                child: const Icon(Icons.book_outlined),
                              ),
                              title: Text('${item.courseCode} — ${item.name}'),
                              subtitle: Text(
                                '${item.language} • ${item.level} • ${item.plannedLessons} buổi • '
                                '${item.durationWeeks} tuần • ${item.status == 'active' ? 'Hoạt động' : 'Ngưng'}\n'
                                '${item.description}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openForm(context, item),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, CourseRecord? course) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CourseFormPage(course: course)),
    );
  }
}
