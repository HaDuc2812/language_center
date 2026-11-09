import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/teacher_model.dart';
import '../repositories/teacher_repository_impl.dart';
import 'teacher_list_viewmodel.dart';

/// AsyncNotifier quản lý trạng thái thực thi các thao tác CUD (Create, Update, Delete, Status Change)
class TeacherActionViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Khởi tạo state ban đầu không có lỗi và không loading
  }

  /// Thêm mới giáo viên
  Future<bool> createTeacher(Teacher teacher) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(teacherRepositoryProvider);
      await repository.createTeacher(teacher);
      ref.invalidate(teacherListStreamProvider);
      ref.invalidate(filteredTeachersProvider);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  /// Cập nhật thông tin giáo viên (mã không thay đổi)
  Future<bool> updateTeacher(Teacher teacher) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(teacherRepositoryProvider);
      await repository.updateTeacher(teacher);
      ref.invalidate(teacherListStreamProvider);
      ref.invalidate(filteredTeachersProvider);
      ref.invalidate(teacherDetailStreamProvider(teacher.id));
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  /// Xóa giáo viên khỏi hệ thống (kiểm tra ràng buộc lớp học)
  Future<bool> deleteTeacher(String teacherId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(teacherRepositoryProvider);
      await repository.deleteTeacher(teacherId);
      ref.invalidate(teacherListStreamProvider);
      ref.invalidate(filteredTeachersProvider);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  /// Thay đổi trạng thái giáo viên (Active <-> Inactive)
  Future<bool> toggleTeacherStatus(
    String teacherId,
    TeacherStatus currentStatus,
  ) async {
    final nextStatus = currentStatus == TeacherStatus.active
        ? TeacherStatus.inactive
        : TeacherStatus.active;

    state = const AsyncLoading();
    try {
      final repository = ref.read(teacherRepositoryProvider);
      await repository.updateTeacherStatus(teacherId, nextStatus);
      ref.invalidate(teacherListStreamProvider);
      ref.invalidate(filteredTeachersProvider);
      ref.invalidate(teacherDetailStreamProvider(teacherId));
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

/// Provider cung cấp TeacherActionViewModel cho các View lắng nghe và tương tác
final teacherActionViewModelProvider =
    AsyncNotifierProvider<TeacherActionViewModel, void>(
  TeacherActionViewModel.new,
);

/// Provider lắng nghe dữ liệu của một giáo viên cụ thể theo ID
final teacherDetailStreamProvider =
    StreamProvider.autoDispose.family<Teacher?, String>((ref, teacherId) async* {
  final repository = ref.watch(teacherRepositoryProvider);
  yield await repository.getTeacherById(teacherId);
  yield* repository.getTeachersStream().map((teachers) {
    try {
      return teachers.firstWhere((t) => t.id == teacherId || t.code == teacherId);
    } catch (_) {
      return null;
    }
  });
});
