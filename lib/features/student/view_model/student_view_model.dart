import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/database_providers.dart';
import '../data/student_repository.dart';
import '../models/student.dart';

part 'student_view_model.g.dart';

// ── Repository provider ──────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
StudentRepository studentRepository(Ref ref) {
  return StudentRepository(ref.watch(databaseHelperProvider));
}

// ── Query providers ──────────────────────────────────────────────────────────

/// Full list provider — used internally for invalidation.
@riverpod
Future<List<Student>> studentList(Ref ref) {
  return ref.watch(studentRepositoryProvider).students();
}

/// Filtered & searched list — used by the list screen.
@riverpod
Future<List<Student>> filteredStudentList(
  Ref ref, {
  String query = '',
  String statusFilter = 'all',
}) {
  return ref
      .watch(studentRepositoryProvider)
      .search(query, statusFilter: statusFilter);
}

/// Single student detail.
@riverpod
Future<Student?> studentDetail(Ref ref, int studentId) {
  return ref.watch(studentRepositoryProvider).studentById(studentId);
}

/// Auto-generate next student code.
@riverpod
Future<String> nextStudentCode(Ref ref) {
  return ref.watch(studentRepositoryProvider).generateNextCode();
}

/// Associated class enrollments for student detail view (SRS UC07).
@riverpod
Future<List<Map<String, Object?>>> studentEnrollments(Ref ref, int studentId) {
  return ref
      .watch(studentRepositoryProvider)
      .studentEnrollmentDetails(studentId);
}

// ── Action view model ────────────────────────────────────────────────────────

@riverpod
class StudentActions extends _$StudentActions {
  @override
  FutureOr<void> build() {}

  /// Add a new student and invalidate list caches.
  Future<int> addStudent({
    required String code,
    required String fullName,
    required String email,
    required String phone,
    required String status,
  }) async {
    state = const AsyncLoading();
    try {
      final id = await ref.read(studentRepositoryProvider).addStudent(
        code: code,
        fullName: fullName,
        email: email,
        phone: phone,
        status: status,
      );
      state = const AsyncData(null);
      _invalidate();
      return id;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Update an existing student.
  Future<void> updateStudent({
    required int id,
    required String code,
    required String fullName,
    required String email,
    required String phone,
    required String status,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(studentRepositoryProvider).updateStudent(
        id: id,
        code: code,
        fullName: fullName,
        email: email,
        phone: phone,
        status: status,
      );
      state = const AsyncData(null);
      _invalidate();
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Change student status (SRS UC06, UC10).
  Future<void> changeStatus({
    required int id,
    required String newStatus,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(studentRepositoryProvider).changeStudentStatus(
        id: id,
        newStatus: newStatus,
      );
      state = const AsyncData(null);
      _invalidate();
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Delete a student (blocked if has enrollment history).
  Future<void> deleteStudent(int id) async {
    state = const AsyncLoading();
    try {
      await ref.read(studentRepositoryProvider).deleteStudent(id);
      state = const AsyncData(null);
      _invalidate();
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _invalidate() {
    ref.invalidate(studentListProvider);
    ref.invalidate(filteredStudentListProvider);
    ref.invalidate(studentDetailProvider);
    ref.invalidate(nextStudentCodeProvider);
    ref.invalidate(studentEnrollmentsProvider);
  }
}
