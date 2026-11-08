import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/course_models.dart';
import '../../../core/providers/database_providers.dart';
import '../../learning_process/view_model/learning_process_view_model.dart';
import '../data/course_repository.dart';

part 'course_view_model.g.dart';

// ── Repository singleton ──
@Riverpod(keepAlive: true)
CourseRepository courseRepository(Ref ref) {
  return CourseRepository(ref.watch(databaseHelperProvider));
}

// ── Query providers (auto‐dispose, dùng ref.watch để rebuild) ──

@riverpod
Future<List<CourseRecord>> courseList(Ref ref) {
  return ref.watch(courseRepositoryProvider).courses();
}

@riverpod
Future<List<CourseRecord>> courseSearch(Ref ref, String query) {
  return ref.watch(courseRepositoryProvider).searchCourses(query);
}

@riverpod
Future<List<ClassroomRecord>> classroomList(Ref ref) {
  return ref.watch(courseRepositoryProvider).classrooms();
}

@riverpod
Future<List<Map<String, Object?>>> activeTeacherList(Ref ref) {
  return ref.watch(courseRepositoryProvider).activeTeachers();
}

// ── Mutation notifier ──

// THÀNH NHƯ THẾ NÀY (Thêm keepAlive: true):
@Riverpod(keepAlive: true)
class CourseActions extends _$CourseActions {
  @override
  FutureOr<void> build() {}

  // ─── Course ───

  Future<void> createCourse({
    required String courseCode,
    required String name,
    required String description,
    required String language,
    required String level,
    required int plannedLessons,
    required int durationWeeks,
  }) async {
    await _run(
      () => ref
          .read(courseRepositoryProvider)
          .createCourse(
            courseCode: courseCode,
            name: name,
            description: description,
            language: language,
            level: level,
            plannedLessons: plannedLessons,
            durationWeeks: durationWeeks,
          ),
    );
    _refresh();
  }

  Future<void> updateCourse({
    required int id,
    required String name,
    required String description,
    required String language,
    required String level,
    required int plannedLessons,
    required int durationWeeks,
    required String status,
  }) async {
    await _run(
      () => ref
          .read(courseRepositoryProvider)
          .updateCourse(
            id: id,
            name: name,
            description: description,
            language: language,
            level: level,
            plannedLessons: plannedLessons,
            durationWeeks: durationWeeks,
            status: status,
          ),
    );
    _refresh();
  }

  Future<void> deleteCourse(int id) async {
    await _run(() => ref.read(courseRepositoryProvider).deleteCourse(id));
    _refresh();
  }

  // ─── Classroom ───

  Future<void> createClassroom({
    required String roomCode,
    required String roomName,
    required int capacity,
  }) async {
    await _run(
      () => ref
          .read(courseRepositoryProvider)
          .createClassroom(
            roomCode: roomCode,
            roomName: roomName,
            capacity: capacity,
          ),
    );
    _refresh();
  }

  Future<void> updateClassroom({
    required int id,
    required String roomCode,
    required String roomName,
    required int capacity,
    required String status,
  }) async {
    await _run(
      () => ref
          .read(courseRepositoryProvider)
          .updateClassroom(
            id: id,
            roomCode: roomCode,
            roomName: roomName,
            capacity: capacity,
            status: status,
          ),
    );
    _refresh();
  }

  Future<void> deleteClassroom(int id) async {
    await _run(() => ref.read(courseRepositoryProvider).deleteClassroom(id));
    _refresh();
  }

  // ─── Study Class ───

  Future<void> createStudyClass({
    required String classCode,
    required String name,
    required int courseId,
    required int teacherId,
    required int roomId,
    required int maxCapacity,
    required DateTime startDate,
    required DateTime endDate,
    required String scheduleDetails,
  }) async {
    await _run(
      () => ref
          .read(courseRepositoryProvider)
          .createClass(
            classCode: classCode,
            name: name,
            courseId: courseId,
            teacherId: teacherId,
            roomId: roomId,
            maxCapacity: maxCapacity,
            startDate: startDate,
            endDate: endDate,
            scheduleDetails: scheduleDetails,
          ),
    );
    _refresh();
  }

  Future<void> updateStudyClass({
    required int id,
    required String name,
    required int teacherId,
    required int roomId,
    required int maxCapacity,
    required DateTime startDate,
    required DateTime endDate,
    required String scheduleDetails,
  }) async {
    await _run(
      () => ref
          .read(courseRepositoryProvider)
          .updateClass(
            id: id,
            name: name,
            teacherId: teacherId,
            roomId: roomId,
            maxCapacity: maxCapacity,
            startDate: startDate,
            endDate: endDate,
            scheduleDetails: scheduleDetails,
          ),
    );
    _refresh();
  }

  Future<void> deleteClass(int id) async {
    await _run(() => ref.read(courseRepositoryProvider).deleteClass(id));
    _refresh();
  }

  Future<void> changeClassStatus({
    required int id,
    required String nextStatus,
    String? reason,
  }) async {
    await _run(
      () => ref
          .read(courseRepositoryProvider)
          .changeClassStatus(id: id, nextStatus: nextStatus, reason: reason),
    );
    _refresh();
  }

  Future<int> saveLesson({
    int? lessonId,
    required int classId,
    required int roomId,
    required String title,
    required DateTime startAt,
    required DateTime endAt,
    required String role,
  }) async {
    state = const AsyncLoading();
    try {
      final id = await ref
          .read(courseRepositoryProvider)
          .saveLesson(
            lessonId: lessonId,
            classId: classId,
            roomId: roomId,
            title: title,
            startAt: startAt,
            endAt: endAt,
            role: role,
          );
      state = const AsyncData(null);
      _refresh();
      return id;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> completeLesson(int lessonId) async {
    await _run(
      () => ref.read(courseRepositoryProvider).completeLesson(lessonId),
    );
    _refresh();
  }

  Future<void> cancelLesson({
    required int lessonId,
    required String reason,
  }) async {
    await _run(
      () => ref
          .read(courseRepositoryProvider)
          .cancelLesson(lessonId: lessonId, reason: reason),
    );
    _refresh();
  }

  Future<void> deleteLesson(int lessonId) async {
    await _run(() => ref.read(courseRepositoryProvider).deleteLesson(lessonId));
    _refresh();
  }

  // ─── Helpers ───

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
    ref.invalidate(courseListProvider);
    ref.invalidate(courseSearchProvider);
    ref.invalidate(classroomListProvider);
    ref.invalidate(activeTeacherListProvider);
    ref.invalidate(classListProvider);
    ref.invalidate(classSessionsProvider);
  }
}
