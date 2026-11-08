import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/models/course_models.dart';

class CourseDataException implements Exception {
  const CourseDataException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CourseRepository {
  CourseRepository(this._databaseHelper);
  final DatabaseHelper _databaseHelper;

  // ──────────────── COURSE ────────────────

  /// Lấy tất cả khóa học, sắp xếp theo mã
  Future<List<CourseRecord>> courses() async {
    final db = await _databaseHelper.database;
    final rows = await db.query('course', orderBy: 'course_code');
    return rows.map(_courseRecord).toList(growable: false);
  }

  /// Tìm kiếm khóa học theo mã hoặc tên
  Future<List<CourseRecord>> searchCourses(String query) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'course',
      where: 'course_code LIKE ? OR name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'course_code',
      limit: 100,
    );
    return rows.map(_courseRecord).toList(growable: false);
  }

  /// Tạo khóa học mới
  Future<int> createCourse({
    required String courseCode,
    required String name,
    required String description,
    required String language,
    required String level,
    required int plannedLessons,
    required int durationWeeks,
  }) async {
    final code = courseCode.trim();
    final courseName = name.trim();
    final courseLanguage = language.trim();
    final courseLevel = level.trim();
    if (code.isEmpty) {
      throw const CourseDataException('Vui lòng nhập mã khóa học.');
    }
    if (courseName.isEmpty) {
      throw const CourseDataException('Vui lòng nhập tên khóa học.');
    }
    if (courseLanguage.isEmpty || courseLevel.isEmpty) {
      throw const CourseDataException('Vui lòng nhập ngôn ngữ và trình độ.');
    }
    if (plannedLessons <= 0) {
      throw const CourseDataException('Số buổi dự kiến phải lớn hơn 0.');
    }
    if (durationWeeks <= 0) {
      throw const CourseDataException('Số tuần phải lớn hơn 0.');
    }

    final db = await _databaseHelper.database;

    // Kiểm tra mã trùng
    final existing = await db.query(
      'course',
      where: 'course_code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const CourseDataException('Mã khóa học đã tồn tại.');
    }

    return db.insert('course', {
      'course_code': code,
      'name': courseName,
      'description': description.trim(),
      'language': courseLanguage,
      'level': courseLevel,
      'planned_lessons': plannedLessons,
      'duration_weeks': durationWeeks,
      'status': 'active',
    });
  }

  /// Cập nhật khóa học
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
    final courseName = name.trim();
    final courseLanguage = language.trim();
    final courseLevel = level.trim();
    if (courseName.isEmpty) {
      throw const CourseDataException('Vui lòng nhập tên khóa học.');
    }
    if (courseLanguage.isEmpty || courseLevel.isEmpty) {
      throw const CourseDataException('Vui lòng nhập ngôn ngữ và trình độ.');
    }
    if (plannedLessons <= 0) {
      throw const CourseDataException('Số buổi dự kiến phải lớn hơn 0.');
    }
    if (durationWeeks <= 0) {
      throw const CourseDataException('Số tuần phải lớn hơn 0.');
    }
    if (!const ['active', 'inactive'].contains(status)) {
      throw const CourseDataException('Trạng thái không hợp lệ.');
    }

    final db = await _databaseHelper.database;
    final updated = await db.update(
      'course',
      {
        'name': courseName,
        'description': description.trim(),
        'language': courseLanguage,
        'level': courseLevel,
        'planned_lessons': plannedLessons,
        'duration_weeks': durationWeeks,
        'status': status,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated == 0) {
      throw const CourseDataException('Không tìm thấy khóa học.');
    }
  }

  /// Xóa khóa học - chỉ xóa được nếu chưa có lớp nào tham chiếu
  Future<void> deleteCourse(int id) async {
    final db = await _databaseHelper.database;

    // Kiểm tra có lớp nào dùng khóa học này không
    final classes = await db.query(
      'classes',
      where: 'course_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (classes.isNotEmpty) {
      throw const CourseDataException(
        'Không thể xóa khóa học đã có lớp học. Hãy chuyển trạng thái sang Ngưng hoạt động.',
      );
    }

    final deleted = await db.delete('course', where: 'id = ?', whereArgs: [id]);
    if (deleted == 0) {
      throw const CourseDataException('Không tìm thấy khóa học.');
    }
  }

  // ──────────────── CLASSROOM ────────────────

  /// Lấy tất cả phòng học
  Future<List<ClassroomRecord>> classrooms() async {
    final db = await _databaseHelper.database;
    final rows = await db.query('classrooms', orderBy: 'room_name');
    return rows.map(_classroomRecord).toList(growable: false);
  }

  /// Tạo phòng học mới
  Future<int> createClassroom({
    required String roomCode,
    required String roomName,
    required int capacity,
  }) async {
    final code = roomCode.trim();
    final name = roomName.trim();
    if (code.isEmpty) {
      throw const CourseDataException('Vui lòng nhập mã phòng.');
    }
    if (name.isEmpty) {
      throw const CourseDataException('Vui lòng nhập tên phòng.');
    }
    if (capacity <= 0) {
      throw const CourseDataException('Sức chứa phải lớn hơn 0.');
    }

    final db = await _databaseHelper.database;
    final existing = await db.query(
      'classrooms',
      where: 'room_code = ? OR room_name = ?',
      whereArgs: [code, name],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const CourseDataException('Mã phòng hoặc tên phòng đã tồn tại.');
    }

    return db.insert('classrooms', {
      'room_code': code,
      'room_name': name,
      'capacity': capacity,
      'status': 'active',
    });
  }

  /// Cập nhật phòng học
  Future<void> updateClassroom({
    required int id,
    required String roomCode,
    required String roomName,
    required int capacity,
    required String status,
  }) async {
    final code = roomCode.trim();
    final name = roomName.trim();
    if (code.isEmpty) {
      throw const CourseDataException('Vui lòng nhập mã phòng.');
    }
    if (name.isEmpty) {
      throw const CourseDataException('Vui lòng nhập tên phòng.');
    }
    if (capacity <= 0) {
      throw const CourseDataException('Sức chứa phải lớn hơn 0.');
    }
    if (!const ['active', 'inactive'].contains(status)) {
      throw const CourseDataException('Trạng thái phòng không hợp lệ.');
    }

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        'classrooms',
        where: '(room_code = ? OR room_name = ?) AND id != ?',
        whereArgs: [code, name, id],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        throw const CourseDataException('Mã phòng hoặc tên phòng đã tồn tại.');
      }

      if (status == 'inactive') {
        final futureLessons = await txn.rawQuery(
          '''
          SELECT 1 FROM sessions
          WHERE room_id = ? AND status = 'planned' AND start_at > ?
          LIMIT 1
          ''',
          [id, DateTime.now().millisecondsSinceEpoch],
        );
        if (futureLessons.isNotEmpty) {
          throw const CourseDataException(
            'Không thể ngưng phòng còn buổi học đã xếp trong tương lai.',
          );
        }
      }

      final affected = await txn.rawQuery(
        '''
        SELECT class_code
        FROM classes
        WHERE room_id = ? AND status IN ('planned', 'open', 'ongoing')
          AND max_capacity > ?
        LIMIT 1
        ''',
        [id, capacity],
      );
      if (affected.isNotEmpty) {
        throw CourseDataException(
          'Sức chứa mới nhỏ hơn sĩ số lớp ${affected.first['class_code']}.',
        );
      }

      final updated = await txn.update(
        'classrooms',
        {
          'room_code': code,
          'room_name': name,
          'capacity': capacity,
          'status': status,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      if (updated == 0) {
        throw const CourseDataException('Không tìm thấy phòng học.');
      }
    });
  }

  /// Xóa phòng học - chỉ xóa được nếu chưa có lớp/buổi nào tham chiếu
  Future<void> deleteClassroom(int id) async {
    final db = await _databaseHelper.database;

    final classes = await db.query(
      'classes',
      where: 'room_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final lessons = await db.query(
      'sessions',
      where: 'room_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (classes.isNotEmpty || lessons.isNotEmpty) {
      throw const CourseDataException(
        'Không thể xóa phòng đã có lớp học hoặc buổi học. Hãy chuyển trạng thái sang Ngưng hoạt động.',
      );
    }

    final deleted = await db.delete(
      'classrooms',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deleted == 0) {
      throw const CourseDataException('Không tìm thấy phòng học.');
    }
  }

  // ──────────────── STUDY CLASS (TẠO / SỬA) ────────────────

  /// Tạo lớp học mới
  Future<int> createClass({
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
    final code = classCode.trim();
    final className = name.trim();
    if (code.isEmpty) {
      throw const CourseDataException('Vui lòng nhập mã lớp.');
    }
    if (className.isEmpty) {
      throw const CourseDataException('Vui lòng nhập tên lớp.');
    }
    if (maxCapacity <= 0) {
      throw const CourseDataException('Sĩ số tối đa phải lớn hơn 0.');
    }
    if (!endDate.isAfter(startDate)) {
      throw const CourseDataException('Ngày kết thúc phải sau ngày bắt đầu.');
    }

    final db = await _databaseHelper.database;
    return db.transaction((txn) async {
      // Kiểm tra mã trùng
      final existing = await txn.query(
        'classes',
        where: 'class_code = ?',
        whereArgs: [code],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        throw const CourseDataException('Mã lớp đã tồn tại.');
      }

      // Kiểm tra course tồn tại
      final course = await txn.query(
        'course',
        where: 'id = ? AND status = ?',
        whereArgs: [courseId, 'active'],
        limit: 1,
      );
      if (course.isEmpty) {
        throw const CourseDataException(
          'Khóa học không tồn tại hoặc đã ngưng.',
        );
      }

      // Kiểm tra teacher tồn tại
      final teacher = await txn.query(
        'teachers',
        where: 'id = ? AND status = ?',
        whereArgs: [teacherId, 'active'],
        limit: 1,
      );
      if (teacher.isEmpty) {
        throw const CourseDataException(
          'Giáo viên không tồn tại hoặc đã ngưng.',
        );
      }

      // Kiểm tra room tồn tại
      final room = await txn.query(
        'classrooms',
        where: 'id = ? AND status = ?',
        whereArgs: [roomId, 'active'],
        limit: 1,
      );
      if (room.isEmpty) {
        throw const CourseDataException(
          'Phòng học không tồn tại hoặc đã ngưng.',
        );
      }
      final roomCapacity = room.single['capacity'] as int;
      if (maxCapacity > roomCapacity) {
        throw CourseDataException(
          'Sĩ số tối đa vượt sức chứa phòng ($roomCapacity).',
        );
      }

      // Kiểm tra giáo viên có bị trùng lịch không
      // (giáo viên đang dạy lớp khác mà thời gian trùng)
      final conflictingTeacher = await txn.rawQuery(
        '''
        SELECT class_code, name FROM classes
        WHERE teacher_id = ? AND status IN ('planned', 'open', 'ongoing')
          AND start_date < ? AND end_date > ?
      ''',
        [teacherId, _endOfDay(endDate), _startOfDay(startDate)],
      );
      if (conflictingTeacher.isNotEmpty) {
        final c = conflictingTeacher.first;
        throw CourseDataException(
          'Giáo viên đang dạy lớp ${c['class_code']} (${c['name']}) '
          'trong khoảng thời gian trùng.',
        );
      }

      return txn.insert('classes', {
        'class_code': code,
        'name': className,
        'course_id': courseId,
        'teacher_id': teacherId,
        'room_id': roomId,
        'current_enrollment_count': 0,
        'max_capacity': maxCapacity,
        'start_date': _startOfDay(startDate),
        'end_date': _endOfDay(endDate),
        'schedule_details': scheduleDetails.trim(),
        'status': 'planned',
      });
    });
  }

  /// Cập nhật lớp học (chỉ khi trạng thái planned hoặc open)
  Future<void> updateClass({
    required int id,
    required String name,
    required int teacherId,
    required int roomId,
    required int maxCapacity,
    required DateTime startDate,
    required DateTime endDate,
    required String scheduleDetails,
  }) async {
    final className = name.trim();
    if (className.isEmpty) {
      throw const CourseDataException('Vui lòng nhập tên lớp.');
    }
    if (!endDate.isAfter(startDate)) {
      throw const CourseDataException('Ngày kết thúc phải sau ngày bắt đầu.');
    }

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final current = await txn.query(
        'classes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (current.isEmpty) {
        throw const CourseDataException('Không tìm thấy lớp học.');
      }

      final currentStatus = current.single['status'] as String;
      if (const ['completed', 'cancelled'].contains(currentStatus)) {
        throw const CourseDataException(
          'Không thể sửa lớp đã hoàn thành hoặc đã hủy.',
        );
      }

      final enrolledCount = current.single['current_enrollment_count'] as int;
      if (maxCapacity < enrolledCount) {
        throw CourseDataException(
          'Sĩ số tối đa ($maxCapacity) không thể nhỏ hơn số học viên '
          'đã đăng ký ($enrolledCount).',
        );
      }
      if (maxCapacity <= 0) {
        throw const CourseDataException('Sĩ số tối đa phải lớn hơn 0.');
      }

      final teacher = await txn.query(
        'teachers',
        where: 'id = ?',
        whereArgs: [teacherId],
        limit: 1,
      );
      if (teacher.isEmpty ||
          (teacher.single['status'] != 'active' &&
              teacherId != current.single['teacher_id'])) {
        throw const CourseDataException(
          'Giáo viên không tồn tại hoặc đã ngưng.',
        );
      }
      final room = await txn.query(
        'classrooms',
        where: 'id = ?',
        whereArgs: [roomId],
        limit: 1,
      );
      if (room.isEmpty ||
          (room.single['status'] != 'active' &&
              roomId != current.single['room_id'])) {
        throw const CourseDataException(
          'Phòng học không tồn tại hoặc đã ngưng.',
        );
      }
      if (maxCapacity > (room.single['capacity'] as int)) {
        throw CourseDataException(
          'Sĩ số tối đa vượt sức chứa phòng (${room.single['capacity']}).',
        );
      }

      final started = await txn.rawQuery(
        '''
        SELECT 1 FROM sessions
        WHERE class_id = ? AND status != 'cancelled' AND start_at <= ?
        LIMIT 1
        ''',
        [id, DateTime.now().millisecondsSinceEpoch],
      );
      if (started.isNotEmpty && teacherId != current.single['teacher_id']) {
        throw const CourseDataException(
          'Không đổi giáo viên sau khi buổi học đầu đã bắt đầu.',
        );
      }

      final startMs = _startOfDay(startDate);
      final endMs = _endOfDay(endDate);
      final conflicting = await txn.rawQuery(
        '''
        SELECT class_code, name FROM classes
        WHERE teacher_id = ? AND id != ?
          AND status IN ('planned', 'open', 'ongoing')
          AND start_date < ? AND end_date > ?
      ''',
        [teacherId, id, endMs, startMs],
      );
      if (conflicting.isNotEmpty) {
        final conflict = conflicting.first;
        throw CourseDataException(
          'Giáo viên đang dạy lớp ${conflict['class_code']} (${conflict['name']}) '
          'trong khoảng thời gian trùng.',
        );
      }

      await txn.update(
        'classes',
        {
          'name': className,
          'teacher_id': teacherId,
          'room_id': roomId,
          'max_capacity': maxCapacity,
          'start_date': startMs,
          'end_date': endMs,
          'schedule_details': scheduleDetails.trim(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.update(
        'sessions',
        {'room_id': roomId},
        where: "class_id = ? AND status = 'planned' AND start_at > ?",
        whereArgs: [id, DateTime.now().millisecondsSinceEpoch],
      );
      await _assertExistingLessonsFit(txn, id);
    });
  }

  Future<void> deleteClass(int id) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'classes',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty || rows.single['status'] != 'planned') {
        throw const CourseDataException(
          'Chỉ xóa lớp dự kiến, chưa mở đăng ký.',
        );
      }
      final enrollments = await txn.query(
        'enrollments',
        where: 'class_id = ?',
        whereArgs: [id],
        limit: 1,
      );
      final lessons = await txn.query(
        'sessions',
        where: 'class_id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (enrollments.isNotEmpty || lessons.isNotEmpty) {
        throw const CourseDataException(
          'Lớp đã có đăng ký hoặc buổi học nên không được xóa.',
        );
      }
      await txn.delete('classes', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> changeClassStatus({
    required int id,
    required String nextStatus,
    String? reason,
  }) async {
    const allowed = {
      'planned': ['open', 'cancelled'],
      'open': ['ongoing', 'cancelled'],
      'ongoing': ['completed', 'cancelled'],
    };
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'classes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const CourseDataException('Không tìm thấy lớp học.');
      }
      final current = rows.single['status'] as String;
      if (current == 'completed' || current == 'cancelled') {
        throw const CourseDataException(
          'Lớp đã hoàn thành hoặc đã hủy không được mở lại.',
        );
      }
      if (!(allowed[current]?.contains(nextStatus) ?? false)) {
        throw CourseDataException('Không chuyển từ $current sang $nextStatus.');
      }

      if (nextStatus == 'ongoing') {
        final started =
            (rows.single['start_date'] as int) <=
            DateTime.now().millisecondsSinceEpoch;
        final enrolled = rows.single['current_enrollment_count'] as int;
        if (!started || enrolled < 1) {
          throw const CourseDataException(
            'Chỉ bắt đầu lớp khi đã tới ngày khai giảng và có ít nhất một học viên.',
          );
        }
      }

      if (nextStatus == 'completed') {
        final openLessons = await txn.rawQuery(
          '''
          SELECT 1 FROM sessions
          WHERE class_id = ? AND status IN ('planned', 'ongoing')
          LIMIT 1
          ''',
          [id],
        );
        final doneLessons = await txn.rawQuery(
          '''
          SELECT 1 FROM sessions
          WHERE class_id = ? AND status = 'completed'
          LIMIT 1
          ''',
          [id],
        );
        final missingResults = await txn.rawQuery(
          '''
          SELECT 1
          FROM enrollments e
          LEFT JOIN learning_results lr
            ON lr.enrollment_id = e.id AND lr.deleted_at IS NULL
          WHERE e.class_id = ? AND e.status = 'enrolled' AND lr.id IS NULL
          LIMIT 1
          ''',
          [id],
        );
        if (openLessons.isNotEmpty ||
            doneLessons.isEmpty ||
            missingResults.isNotEmpty) {
          throw const CourseDataException(
            'Cần hoàn thành hết buổi học, có ít nhất một buổi đã hoàn thành, '
            'và mọi học viên đang học đã có điểm.',
          );
        }
      }

      if (nextStatus == 'cancelled') {
        if (reason == null || reason.trim().isEmpty) {
          throw const CourseDataException('Cần nhập lý do hủy lớp.');
        }
        final activeEnrollments = await txn.query(
          'enrollments',
          where: 'class_id = ? AND status = ?',
          whereArgs: [id, 'enrolled'],
          limit: 1,
        );
        final scheduled = await txn.query(
          'sessions',
          where: 'class_id = ? AND status = ?',
          whereArgs: [id, 'planned'],
          limit: 1,
        );
        if (activeEnrollments.isNotEmpty || scheduled.isNotEmpty) {
          throw const CourseDataException(
            'Hãy hủy các đăng ký đang học và các buổi đã xếp trước khi hủy lớp.',
          );
        }
      }

      final updated = await txn.update(
        'classes',
        {'status': nextStatus},
        where: 'id = ? AND status = ?',
        whereArgs: [id, current],
      );
      if (updated != 1) {
        throw const CourseDataException(
          'Trạng thái lớp vừa thay đổi. Hãy tải lại.',
        );
      }
    });
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
    if (role != 'admin' && role != 'staff') {
      throw const CourseDataException(
        'Chỉ admin hoặc nhân viên được xếp lịch.',
      );
    }
    final name = title.trim();
    if (name.isEmpty) {
      throw const CourseDataException('Vui lòng nhập tên buổi học.');
    }
    if (!endAt.isAfter(startAt)) {
      throw const CourseDataException(
        'Thời gian kết thúc phải sau thời gian bắt đầu.',
      );
    }

    final db = await _databaseHelper.database;
    return db.transaction((txn) async {
      final classes = await txn.rawQuery(
        '''
        SELECT c.status, c.teacher_id, c.max_capacity, c.start_date, c.end_date,
               r.capacity AS room_capacity, r.status AS room_status,
               t.status AS teacher_status
        FROM classes c
        JOIN classrooms r ON r.id = ?
        JOIN teachers t ON t.id = c.teacher_id
        WHERE c.id = ?
        ''',
        [roomId, classId],
      );
      if (classes.isEmpty) {
        throw const CourseDataException('Không tìm thấy lớp hoặc phòng.');
      }
      final row = classes.single;
      if (!const ['planned', 'open', 'ongoing'].contains(row['status'])) {
        throw const CourseDataException(
          'Chỉ xếp buổi cho lớp dự kiến, đang mở hoặc đang diễn ra.',
        );
      }
      if (row['teacher_status'] != 'active' || row['room_status'] != 'active') {
        throw const CourseDataException(
          'Giáo viên và phòng của buổi học phải đang hoạt động.',
        );
      }
      final startMs = startAt.millisecondsSinceEpoch;
      final endMs = endAt.millisecondsSinceEpoch;
      if (startMs < (row['start_date'] as int) ||
          endMs > (row['end_date'] as int)) {
        throw const CourseDataException(
          'Buổi học phải nằm trong ngày của lớp.',
        );
      }
      if ((row['max_capacity'] as int) > (row['room_capacity'] as int)) {
        throw const CourseDataException(
          'Phòng không đủ sức chứa cho sĩ số của lớp.',
        );
      }

      if (lessonId != null) {
        final current = await txn.query(
          'sessions',
          where: 'id = ? AND class_id = ?',
          whereArgs: [lessonId, classId],
          limit: 1,
        );
        if (current.isEmpty || current.single['status'] != 'planned') {
          throw const CourseDataException(
            'Chỉ dời buổi đang ở trạng thái đã xếp.',
          );
        }
        if ((current.single['start_at'] as int) <=
            DateTime.now().millisecondsSinceEpoch) {
          throw const CourseDataException(
            'Buổi học đã bắt đầu nên không được dời.',
          );
        }
        final attendance = await txn.query(
          'attendance',
          where: 'session_id = ?',
          whereArgs: [lessonId],
          limit: 1,
        );
        if (attendance.isNotEmpty) {
          throw const CourseDataException(
            'Buổi đã có điểm danh nên không được dời.',
          );
        }
        await _assertNoOverlap(
          txn,
          lessonId: lessonId,
          classId: classId,
          teacherId: row['teacher_id'] as int,
          roomId: roomId,
          startAt: startMs,
          endAt: endMs,
        );
        await txn.update(
          'sessions',
          {
            'room_id': roomId,
            'title': name,
            'start_at': startMs,
            'end_at': endMs,
          },
          where: 'id = ?',
          whereArgs: [lessonId],
        );
        return lessonId;
      }

      await _assertNoOverlap(
        txn,
        lessonId: 0,
        classId: classId,
        teacherId: row['teacher_id'] as int,
        roomId: roomId,
        startAt: startMs,
        endAt: endMs,
      );
      final numberRows = await txn.rawQuery(
        'SELECT COALESCE(MAX(session_number), 0) + 1 AS next_number '
        'FROM sessions WHERE class_id = ?',
        [classId],
      );
      return txn.insert('sessions', {
        'class_id': classId,
        'room_id': roomId,
        'session_number': numberRows.single['next_number'] as int,
        'title': name,
        'start_at': startMs,
        'end_at': endMs,
        'status': 'planned',
      });
    });
  }

  Future<void> completeLesson(int lessonId) async {
    final db = await _databaseHelper.database;
    final updated = await db.rawUpdate(
      '''
      UPDATE sessions
      SET status = 'completed'
      WHERE id = ? AND status IN ('planned', 'ongoing') AND end_at <= ?
      ''',
      [lessonId, DateTime.now().millisecondsSinceEpoch],
    );
    if (updated != 1) {
      throw const CourseDataException(
        'Chỉ hoàn thành buổi đã xếp hoặc đang diễn ra và đã qua giờ kết thúc.',
      );
    }
  }

  Future<void> cancelLesson({
    required int lessonId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw const CourseDataException('Cần nhập lý do hủy buổi học.');
    }
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final attendance = await txn.query(
        'attendance',
        where: 'session_id = ?',
        whereArgs: [lessonId],
        limit: 1,
      );
      if (attendance.isNotEmpty) {
        throw const CourseDataException(
          'Buổi đã có điểm danh nên không được hủy.',
        );
      }
      final updated = await txn.update(
        'sessions',
        {'status': 'cancelled', 'cancel_reason': reason.trim()},
        where: 'id = ? AND status = ?',
        whereArgs: [lessonId, 'planned'],
      );
      if (updated != 1) {
        throw const CourseDataException(
          'Chỉ hủy buổi đang ở trạng thái đã xếp.',
        );
      }
    });
  }

  Future<void> deleteLesson(int lessonId) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'sessions',
        where: 'id = ?',
        whereArgs: [lessonId],
        limit: 1,
      );
      if (rows.isEmpty ||
          (rows.single['start_at'] as int) <=
              DateTime.now().millisecondsSinceEpoch) {
        throw const CourseDataException('Chỉ xóa buổi chưa bắt đầu.');
      }
      final attendance = await txn.query(
        'attendance',
        where: 'session_id = ?',
        whereArgs: [lessonId],
        limit: 1,
      );
      if (attendance.isNotEmpty) {
        throw const CourseDataException(
          'Buổi đã có điểm danh nên không được xóa.',
        );
      }
      await txn.delete('sessions', where: 'id = ?', whereArgs: [lessonId]);
    });
  }

  Future<void> _assertNoOverlap(
    DatabaseExecutor txn, {
    required int lessonId,
    required int classId,
    required int teacherId,
    required int roomId,
    required int startAt,
    required int endAt,
  }) async {
    final rows = await txn.rawQuery(
      '''
      SELECT c.class_code, se.title, se.class_id, c.teacher_id, se.room_id
      FROM sessions se
      JOIN classes c ON c.id = se.class_id
      WHERE se.status != 'cancelled'
        AND se.id != ?
        AND se.start_at < ?
        AND se.end_at > ?
        AND (se.class_id = ? OR c.teacher_id = ? OR se.room_id = ?)
      LIMIT 1
      ''',
      [lessonId, endAt, startAt, classId, teacherId, roomId],
    );
    if (rows.isEmpty) return;
    final row = rows.single;
    final who = row['class_id'] == classId
        ? 'lớp này'
        : row['teacher_id'] == teacherId
        ? 'giáo viên'
        : 'phòng học';
    throw CourseDataException(
      'Trùng lịch $who với ${row['class_code']} — ${row['title']}.',
    );
  }

  Future<void> _assertExistingLessonsFit(
    DatabaseExecutor txn,
    int classId,
  ) async {
    final classes = await txn.query(
      'classes',
      where: 'id = ?',
      whereArgs: [classId],
      limit: 1,
    );
    final learningClass = classes.single;
    final lessons = await txn.query(
      'sessions',
      where: "class_id = ? AND status != 'cancelled'",
      whereArgs: [classId],
    );
    for (final lesson in lessons) {
      final start = lesson['start_at'] as int;
      final end = lesson['end_at'] as int;
      if (start < (learningClass['start_date'] as int) ||
          end > (learningClass['end_date'] as int)) {
        throw const CourseDataException(
          'Buổi học nằm ngoài ngày của lớp sau khi đổi lịch.',
        );
      }
      await _assertNoOverlap(
        txn,
        lessonId: lesson['id'] as int,
        classId: classId,
        teacherId: learningClass['teacher_id'] as int,
        roomId: lesson['room_id'] as int,
        startAt: start,
        endAt: end,
      );
    }
  }

  int _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

  int _endOfDay(DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
    23,
    59,
    59,
  ).millisecondsSinceEpoch;

  // ──────────────── HELPERS ────────────────

  /// Lấy danh sách giáo viên active (dùng cho dropdown chọn giáo viên)
  Future<List<Map<String, Object?>>> activeTeachers() async {
    final db = await _databaseHelper.database;
    return db.query(
      'teachers',
      columns: ['id', 'teacher_code', 'full_name', 'specialization', 'status'],
      orderBy:
          "CASE status WHEN 'active' THEN 0 ELSE 1 END, full_name COLLATE NOCASE",
    );
  }

  CourseRecord _courseRecord(Map<String, Object?> row) => CourseRecord(
    id: row['id'] as int,
    courseCode: row['course_code'] as String,
    name: row['name'] as String,
    description: row['description'] as String,
    language: row['language'] as String? ?? '',
    level: row['level'] as String? ?? '',
    plannedLessons: row['planned_lessons'] as int? ?? 1,
    durationWeeks: row['duration_weeks'] as int,
    status: row['status'] as String,
  );

  ClassroomRecord _classroomRecord(Map<String, Object?> row) => ClassroomRecord(
    id: row['id'] as int,
    roomCode: row['room_code'] as String? ?? '',
    roomName: row['room_name'] as String,
    capacity: row['capacity'] as int,
    status: row['status'] as String,
  );
}
