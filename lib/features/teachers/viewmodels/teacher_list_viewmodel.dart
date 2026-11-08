import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/teacher_model.dart';
import '../repositories/teacher_repository_impl.dart';

/// State quản lý các tiêu chí tìm kiếm và lọc danh sách giáo viên
class TeacherFilterState {
  final String searchQuery;
  final TeacherStatus? statusFilter; // null = Tất cả

  const TeacherFilterState({
    this.searchQuery = '',
    this.statusFilter,
  });

  TeacherFilterState copyWith({
    String? searchQuery,
    TeacherStatus? Function()? statusFilter,
  }) {
    return TeacherFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
    );
  }
}

/// Notifier điều khiển bộ lọc danh sách giáo viên
class TeacherFilterNotifier extends Notifier<TeacherFilterState> {
  @override
  TeacherFilterState build() => const TeacherFilterState();

  /// Cập nhật từ khóa tìm kiếm (họ tên, mã, chuyên môn)
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Cập nhật lọc trạng thái (Active / Inactive / null)
  void setStatusFilter(TeacherStatus? status) {
    state = state.copyWith(statusFilter: () => status);
  }

  /// Khôi phục toàn bộ bộ lọc
  void resetFilters() {
    state = const TeacherFilterState();
  }
}

/// Provider lưu trữ trạng thái bộ lọc
final teacherFilterProvider =
    NotifierProvider<TeacherFilterNotifier, TeacherFilterState>(
  TeacherFilterNotifier.new,
);

/// StreamProvider lắng nghe danh sách toàn bộ giáo viên theo thời gian thực từ Firestore
final teacherListStreamProvider =
    StreamProvider.autoDispose<List<Teacher>>((ref) {
  final repository = ref.watch(teacherRepositoryProvider);
  return repository.getTeachersStream();
});

/// Provider tính toán danh sách giáo viên sau khi đã áp dụng tìm kiếm và lọc trạng thái
final filteredTeachersProvider =
    Provider.autoDispose<AsyncValue<List<Teacher>>>((ref) {
  final teachersAsync = ref.watch(teacherListStreamProvider);
  final filter = ref.watch(teacherFilterProvider);

  return teachersAsync.whenData((teachers) {
    return teachers.where((teacher) {
      // 1. Lọc theo trạng thái (Active / Inactive)
      if (filter.statusFilter != null &&
          teacher.status != filter.statusFilter) {
        return false;
      }

      // 2. Lọc theo từ khóa tìm kiếm realtime (mã, tên, chuyên môn)
      final query = filter.searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchCode = teacher.code.toLowerCase().contains(query);
        final matchName = teacher.fullName.toLowerCase().contains(query);
        final matchSpecialty = teacher.specialties.any(
          (s) => s.toLowerCase().contains(query),
        );

        if (!matchCode && !matchName && !matchSpecialty) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});

