import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/models/learning_records.dart';
import '../data/learning_repository.dart';

part 'learning_process_view_model.g.dart';

@Riverpod(keepAlive: true)
LearningRepository learningRepository(Ref ref) {
  return LearningRepository(ref.watch(databaseHelperProvider));
}

@riverpod
Future<List<ClassRecord>> classList(Ref ref) {
  return ref.watch(learningRepositoryProvider).classes();
}

@riverpod
Future<List<EnrollmentRecord>> enrollmentList(Ref ref) {
  return ref.watch(learningRepositoryProvider).enrollments();
}

@riverpod
Future<List<EnrollmentRecord>> classEnrollmentList(Ref ref, int classId) {
  return ref.watch(learningRepositoryProvider).enrollments(classId: classId);
}

@riverpod
Future<List<StudentRecord>> studentSearch(Ref ref, String query) {
  return ref.watch(learningRepositoryProvider).searchStudents(query);
}

@riverpod
Future<List<StudentHistoryRecord>> studentHistory(Ref ref, int studentId) {
  return ref.watch(learningRepositoryProvider).studentHistory(studentId);
}

@riverpod
Future<List<SessionRecord>> classSessions(Ref ref, int classId) {
  return ref.watch(learningRepositoryProvider).sessions(classId);
}

@riverpod
Future<List<AttendanceRecord>> sessionAttendance(Ref ref, int sessionId) {
  return ref.watch(learningRepositoryProvider).attendance(sessionId);
}

@riverpod
Future<List<EnrollmentRecord>> classResults(Ref ref, int classId) {
  return ref.watch(learningRepositoryProvider).enrollments(classId: classId);
}

@riverpod
class LearningProcessActions extends _$LearningProcessActions {
  @override
  FutureOr<void> build() {}

  Future<void> enroll({
    required String studentCode,
    required int classId,
  }) async {
    await _run(
      () => ref
          .read(learningRepositoryProvider)
          .enroll(studentCode: studentCode, classId: classId),
    );
    _refresh();
  }

  Future<void> cancelEnrollment({
    required int enrollmentId,
    required String reason,
  }) async {
    await _run(
      () => ref
          .read(learningRepositoryProvider)
          .cancelEnrollment(enrollmentId: enrollmentId, reason: reason),
    );
    _refresh();
  }

  Future<int> createSession({
    required int classId,
    required String title,
    required DateTime startAt,
    required DateTime endAt,
    required String role,
  }) async {
    state = const AsyncLoading();
    try {
      final sessionId = await ref
          .read(learningRepositoryProvider)
          .createSession(
            classId: classId,
            title: title,
            startAt: startAt,
            endAt: endAt,
            role: role,
          );
      state = const AsyncData(null);
      _refresh();
      return sessionId;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> saveAttendance({
    required int enrollmentId,
    required int sessionId,
    required String status,
    required String note,
    required String role,
    String? correctionReason,
  }) async {
    await _run(
      () => ref
          .read(learningRepositoryProvider)
          .saveAttendance(
            enrollmentId: enrollmentId,
            sessionId: sessionId,
            status: status,
            note: note,
            role: role,
            correctionReason: correctionReason,
          ),
    );
    _refresh();
  }

  Future<void> deleteAttendance({
    required int enrollmentId,
    required int sessionId,
    required String role,
    required String reason,
  }) async {
    await _run(
      () => ref
          .read(learningRepositoryProvider)
          .deleteAttendance(
            enrollmentId: enrollmentId,
            sessionId: sessionId,
            role: role,
            reason: reason,
          ),
    );
    _refresh();
  }

  Future<void> saveResult({
    required int enrollmentId,
    required double score,
    required String comment,
    required String role,
    String? correctionReason,
  }) async {
    await _run(
      () => ref
          .read(learningRepositoryProvider)
          .saveResult(
            enrollmentId: enrollmentId,
            score: score,
            comment: comment,
            role: role,
            correctionReason: correctionReason,
          ),
    );
    _refresh();
  }

  Future<void> deleteResult({
    required int enrollmentId,
    required String role,
    required String reason,
  }) async {
    await _run(
      () => ref
          .read(learningRepositoryProvider)
          .deleteResult(enrollmentId: enrollmentId, role: role, reason: reason),
    );
    _refresh();
  }

  Future<void> _run(Future<void> Function() operation) async {
    state = const AsyncLoading();
    try {
      await operation();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _refresh() {
    ref.invalidate(classListProvider);
    ref.invalidate(enrollmentListProvider);
    ref.invalidate(classEnrollmentListProvider);
    ref.invalidate(studentSearchProvider);
    ref.invalidate(studentHistoryProvider);
    ref.invalidate(classSessionsProvider);
    ref.invalidate(sessionAttendanceProvider);
    ref.invalidate(classResultsProvider);
  }
}
