import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student.dart';
import '../view_model/student_view_model.dart';
import 'student_detail_page.dart';
import 'student_form_page.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(
      filteredStudentListProvider(query: _query, statusFilter: _statusFilter),
    );

    return Scaffold(
      body: Column(
        children: [
          // ── Filter bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã, tên, email, SĐT…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                DropdownMenuItem(value: 'studying', child: Text('Đang học')),
                DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                DropdownMenuItem(value: 'dropped', child: Text('Đã nghỉ')),
                DropdownMenuItem(
                  value: 'graduated',
                  child: Text('Đã tốt nghiệp'),
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
          // ── Student count badge ──
          studentsAsync.when(
            data: (items) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${items.length} học viên',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          // ── List ──
          Expanded(
            child: studentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                message: 'Không tải được danh sách học viên: $error',
                onRetry: () =>
                    ref.invalidate(filteredStudentListProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyView(
                    hasFilter: _query.isNotEmpty || _statusFilter != 'all',
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _statusFilter = 'all';
                      });
                    },
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(filteredStudentListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: items.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) =>
                        _StudentTile(student: items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const StudentFormPage()),
        ),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Thêm học viên'),
      ),
    );
  }
}

// ── Student list tile ────────────────────────────────────────────────────────

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student});

  final Student student;

  Color _statusColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (student.status) {
      'studying' || 'active' => cs.primary,
      'graduated' => Colors.green.shade700,
      'dropped' || 'inactive' => cs.outline,
      _ => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _statusColor(context).withValues(alpha: 0.15),
          child: Text(
            student.fullName.isNotEmpty
                ? student.fullName[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: _statusColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(student.fullName),
        subtitle: Text(
          '${student.code}'
          '${student.phone.isNotEmpty ? ' • ${student.phone}' : ''}'
          '${student.email.isNotEmpty ? '\n${student.email}' : ''}',
        ),
        isThreeLine: student.email.isNotEmpty,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student.statusDisplay,
                style: TextStyle(
                  fontSize: 11,
                  color: _statusColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StudentDetailPage(studentId: student.id),
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error helpers ────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilter, required this.onClear});

  final bool hasFilter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'Không tìm thấy học viên phù hợp.'
                  : 'Chưa có học viên nào.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onClear, child: const Text('Xóa bộ lọc')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
