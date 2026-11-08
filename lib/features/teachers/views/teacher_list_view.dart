import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/teacher_model.dart';
import '../viewmodels/teacher_list_viewmodel.dart';
import 'teacher_detail_view.dart';
import 'teacher_form_view.dart';

/// Màn hình danh sách giáo viên với tìm kiếm realtime và lọc theo trạng thái
class TeacherListView extends ConsumerStatefulWidget {
  final bool showAppBar;

  const TeacherListView({super.key, this.showAppBar = true});

  @override
  ConsumerState<TeacherListView> createState() => _TeacherListViewState();
}

class _TeacherListViewState extends ConsumerState<TeacherListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeachersAsync = ref.watch(filteredTeachersProvider);
    final filterState = ref.watch(teacherFilterProvider);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Quản lý giáo viên'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  tooltip: 'Thêm giáo viên mới',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TeacherFormView(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TeacherFormView(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm giáo viên'),
      ),
      body: Column(
        children: [
          // Header: Thanh tìm kiếm & Bộ lọc
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Ô tìm kiếm realtime
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã, họ tên hoặc chuyên môn...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(teacherFilterProvider.notifier)
                                  .setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    ref
                        .read(teacherFilterProvider.notifier)
                        .setSearchQuery(value);
                  },
                ),
                const SizedBox(height: 8),

                // Thanh chọn bộ lọc trạng thái
                Row(
                  children: [
                    const Text(
                      'Trạng thái:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Tất cả'),
                              selected: filterState.statusFilter == null,
                              onSelected: (selected) {
                                if (selected) {
                                  ref
                                      .read(teacherFilterProvider.notifier)
                                      .setStatusFilter(null);
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('Đang hoạt động'),
                              selected: filterState.statusFilter ==
                                  TeacherStatus.active,
                              avatar: filterState.statusFilter ==
                                      TeacherStatus.active
                                  ? const Icon(Icons.check, size: 16)
                                  : null,
                              onSelected: (selected) {
                                ref
                                    .read(teacherFilterProvider.notifier)
                                    .setStatusFilter(
                                      selected ? TeacherStatus.active : null,
                                    );
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('Ngưng hoạt động'),
                              selected: filterState.statusFilter ==
                                  TeacherStatus.inactive,
                              onSelected: (selected) {
                                ref
                                    .read(teacherFilterProvider.notifier)
                                    .setStatusFilter(
                                      selected ? TeacherStatus.inactive : null,
                                    );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body: Danh sách giáo viên (hỗ trợ loading, error, empty)
          Expanded(
            child: filteredTeachersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Lỗi khi tải danh sách giáo viên',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(teacherListStreamProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (teachers) {
                if (teachers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            filterState.searchQuery.isNotEmpty ||
                                    filterState.statusFilter != null
                                ? 'Không tìm thấy giáo viên phù hợp bộ lọc.'
                                : 'Chưa có hồ sơ giáo viên nào trong hệ thống.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (filterState.searchQuery.isNotEmpty ||
                              filterState.statusFilter != null)
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(teacherFilterProvider.notifier)
                                    .resetFilters();
                              },
                              icon: const Icon(Icons.filter_alt_off),
                              label: const Text('Xóa bộ lọc'),
                            )
                          else
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TeacherFormView(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm giáo viên đầu tiên'),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: teachers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    final isActive = teacher.isActive;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TeacherDetailView(
                                teacherId: teacher.id,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isActive
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                        : Colors.grey.shade300,
                                    child: Text(
                                      teacher.fullName.isNotEmpty
                                          ? teacher.fullName
                                              .trim()
                                              .split(' ')
                                              .last[0]
                                              .toUpperCase()
                                          : 'G',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          teacher.fullName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Mã: ${teacher.code}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
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
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      teacher.email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    teacher.phoneNumber,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (teacher.specialties.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6.0,
                                  runSpacing: 4.0,
                                  children: teacher.specialties.take(4).map((s) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        s,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                    );
                                  }).toList()
                                    ..addAll(
                                      teacher.specialties.length > 4
                                          ? [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '+${teacher.specialties.length - 4}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            ]
                                          : [],
                                    ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

