import '../../../core/database/database_helper.dart';
import '../../../core/models/learning_records.dart';

class LearningDataException implements Exception {
  const LearningDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LearningRepository {
  LearningRepository(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  Future<List<ClassRecord>> classes() async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT c.*, co.name AS course_name, t.full_name AS teacher_name,
             r.room_name AS room_name
      FROM classes c
      JOIN course co ON co.id = c.course_id
      JOIN teachers t ON t.id = c.teacher_id
      JOIN classrooms r ON r.id = c.room_id
      ORDER BY c.start_date DESC, c.class_code
    ''');
    return rows.map(_classRecord).toList(growable: false);
  }

  Future<List<EnrollmentRecord>> enrollments({int? classId}) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT e.*, s.student_code, s.full_name AS student_name,
             c.class_code, c.name AS class_name,
             CASE WHEN lr.deleted_at IS NULL THEN lr.score END AS score,
             CASE WHEN lr.deleted_at IS NULL THEN lr.comment END AS result_comment
      FROM enrollments e
      JOIN students s ON s.id = e.student_id
      JOIN classes c ON c.id = e.class_id
      LEFT JOIN learning_results lr ON lr.enrollment_id = e.id
      ${classId == null ? '' : 'WHERE e.class_id = ?'}
      ORDER BY CASE e.status WHEN 'enrolled' THEN 0 ELSE 1 END,
               s.full_name COLLATE NOCASE
      ''', classId == null ? null : [classId]);
    return rows.map(_enrollmentRecord).toList(growable: false);
  }

  Future<List<StudentRecord>> searchStudents(String query) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'students',
      where: 'student_code LIKE ? OR full_name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'full_name COLLATE NOCASE',
      limit: 100,
    );
    return rows.map(_studentRecord).toList(growable: false);
  }

  Future<List<EnrollmentRecord>> studentEnrollments(int studentId) async {
    final all = await enrollments();
    return all.where((item) => item.studentId == studentId).toList();
  }

  Future<List<StudentHistoryRecord>> studentHistory(int studentId) async {
    final db = await _databaseHelper.database;
    final enrollmentRecords = await db.rawQuery(
      '''
      SELECT e.*, s.student_code, s.full_name AS student_name,
             c.class_code, c.name AS class_name,
             CASE WHEN lr.deleted_at IS NULL THEN lr.score END AS score,
             CASE WHEN lr.deleted_at IS NULL THEN lr.comment END AS result_comment
      FROM enrollments e
      JOIN students s ON s.id = e.student_id
      JOIN classes c ON c.id = e.class_id
      LEFT JOIN learning_results lr ON lr.enrollment_id = e.id
      WHERE e.student_id = ?
      ORDER BY e.enrolled_at DESC
    ''',
      [studentId],
    );
    final results = <StudentHistoryRecord>[];
    for (final row in enrollmentRecords) {
      final enrollment = _enrollmentRecord(row);
      final attendanceRows = await db.rawQuery(
        '''
        SELECT se.title AS session_title, a.status, a.note
        FROM attendance a
        JOIN sessions se ON se.id = a.session_id
        WHERE a.enrollment_id = ? AND a.deleted_at IS NULL
        ORDER BY se.start_at
        ''',
        [enrollment.id],
      );
      results.add(
        StudentHistoryRecord(
          enrollment: enrollment,
          attendances: attendanceRows
              .map(
                (attendance) => (
                  sessionTitle: attendance['session_title'] as String,
                  status: attendance['status'] as String,
                  note: attendance['note'] as String,
                ),
              )
              .toList(growable: false),
        ),
      );
    }
    return results;
  }

  Future<List<SessionRecord>> sessions(int classId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'sessions',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'start_at',
    );
    return rows.map(_sessionRecord).toList(growable: false);
  }

  Future<int> createSession({
    required int classId,
    required String title,
    required DateTime startAt,
    required DateTime endAt,
    required String role,
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw const LearningDataException('Vui lòng nhập tên buổi học.');
    }
    if (!endAt.isAfter(startAt)) {
      throw const LearningDataException(
        'Thời gian kết thúc phải sau thời gian bắt đầu.',
      );
    }
    if (role != 'admin' && role != 'staff') {
      throw const LearningDataException(
        'Chỉ admin hoặc nhân viên được tạo buổi học.',
      );
    }

    final db = await _databaseHelper.database;
    return db.transaction((txn) async {
      final classes = await txn.query(
        'classes',
        columns: ['room_id', 'status'],
        where: 'id = ?',
        whereArgs: [classId],
        limit: 1,
      );
      if (classes.isEmpty) {
        throw const LearningDataException('Không tìm thấy lớp học.');
      }
      if (classes.single['status'] != 'ongoing') {
        throw const LearningDataException(
          'Chỉ tạo buổi học cho lớp đang diễn ra.',
        );
      }

      final numberRows = await txn.rawQuery(
        'SELECT COALESCE(MAX(session_number), 0) + 1 AS next_number '
        'FROM sessions WHERE class_id = ?',
        [classId],
      );
      final number = numberRows.single['next_number'] as int;
      final now = DateTime.now();
      final status = endAt.isBefore(now)
          ? 'completed'
          : startAt.isAfter(now)
          ? 'planned'
          : 'ongoing';
      return txn.insert('sessions', {
        'class_id': classId,
        'room_id': classes.single['room_id'],
        'session_number': number,
        'title': normalizedTitle,
        'start_at': startAt.millisecondsSinceEpoch,
        'end_at': endAt.millisecondsSinceEpoch,
        'status': status,
      });
    });
  }

  Future<List<AttendanceRecord>> attendance(int sessionId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT e.id AS enrollment_id, s.student_code, s.full_name,
             a.id AS attendance_id, a.status AS attendance_status, a.note
      FROM sessions se
      JOIN enrollments e ON e.class_id = se.class_id AND e.status = 'enrolled'
      JOIN students s ON s.id = e.student_id
      LEFT JOIN attendance a ON a.enrollment_id = e.id AND a.session_id = se.id
        AND a.deleted_at IS NULL
      WHERE se.id = ? AND e.enrolled_at <= se.start_at
      ORDER BY s.full_name COLLATE NOCASE
      ''',
      [sessionId],
    );
    return rows
        .map(
          (row) => AttendanceRecord(
            enrollmentId: row['enrollment_id'] as int,
            studentCode: row['student_code'] as String,
            studentName: row['full_name'] as String,
            attendanceId: row['attendance_id'] as int?,
            status: row['attendance_status'] as String?,
            note: row['note'] as String? ?? '',
          ),
        )
        .toList(growable: false);
  }

  Future<void> enroll({
    required String studentCode,
    required int classId,
  }) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final students = await txn.query(
        'students',
        where: 'student_code = ?',
        whereArgs: [studentCode],
        limit: 1,
      );
      if (students.isEmpty) {
        throw const LearningDataException('Không tìm thấy học viên.');
      }
      final student = students.single;
      if (student['status'] != 'studying' && student['status'] != 'active') {
        throw const LearningDataException(
          'Học viên không ở trạng thái có thể đăng ký.',
        );
      }
      final classes = await txn.query(
        'classes',
        where: 'id = ?',
        whereArgs: [classId],
        limit: 1,
      );
      if (classes.isEmpty) {
        throw const LearningDataException('Không tìm thấy lớp học.');
      }
      final learningClass = classes.single;
      if (!const ['open', 'ongoing'].contains(learningClass['status'])) {
        throw const LearningDataException('Lớp hiện không nhận đăng ký.');
      }
      final existing = await txn.query(
        'enrollments',
        where: 'student_id = ? AND class_id = ?',
        whereArgs: [student['id'], classId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        throw const LearningDataException(
          'Cặp học viên-lớp này đã có đăng ký. Đăng ký lại chưa được hỗ trợ.',
        );
      }
      final current = learningClass['current_enrollment_count'] as int;
      final capacity = learningClass['max_capacity'] as int;
      if (current >= capacity) {
        throw const LearningDataException('Lớp đã đủ số lượng học viên.');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await txn.insert('enrollments', {
        'student_id': student['id'],
        'class_id': classId,
        'status': 'enrolled',
        'enrolled_at': now,
      });
      final updated = await txn.rawUpdate(
        '''
        UPDATE classes
        SET current_enrollment_count = current_enrollment_count + 1
        WHERE id = ? AND current_enrollment_count < max_capacity
        ''',
        [classId],
      );
      if (updated != 1) {
        throw const LearningDataException(
          'Không thể cập nhật sĩ số lớp. Vui lòng tải lại.',
        );
      }
    });
  }

  Future<void> cancelEnrollment({
    required int enrollmentId,
    required String reason,
  }) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        '''
        SELECT e.status, e.class_id, c.status AS class_status
        FROM enrollments e JOIN classes c ON c.id = e.class_id
        WHERE e.id = ?
        ''',
        [enrollmentId],
      );
      if (rows.isEmpty || rows.single['status'] != 'enrolled') {
        throw const LearningDataException(
          'Đăng ký không còn ở trạng thái đang học.',
        );
      }
      final row = rows.single;
      if (!const ['open', 'ongoing'].contains(row['class_status'])) {
        throw const LearningDataException(
          'Chỉ được hủy đăng ký khi lớp đang mở hoặc đang diễn ra.',
        );
      }
      await txn.update(
        'enrollments',
        {
          'status': 'cancelled',
          'cancelled_at': DateTime.now().millisecondsSinceEpoch,
          'cancel_reason': reason.trim(),
        },
        where: 'id = ? AND status = ?',
        whereArgs: [enrollmentId, 'enrolled'],
      );
      await txn.rawUpdate(
        '''
        UPDATE classes SET current_enrollment_count =
          CASE WHEN current_enrollment_count > 0
               THEN current_enrollment_count - 1 ELSE 0 END
        WHERE id = ?
        ''',
        [row['class_id']],
      );
    });
  }

  Future<void> saveAttendance({
    required int enrollmentId,
    required int sessionId,
    required String status,
    required String note,
    required String role,
    String? correctionReason,
  }) async {
    if (!const ['present', 'absent', 'late', 'excused'].contains(status)) {
      throw const LearningDataException('Trạng thái điểm danh không hợp lệ.');
    }
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        '''
        SELECT e.class_id, e.status AS enrollment_status, e.enrolled_at,
               se.class_id AS session_class_id, se.start_at,
               se.status AS session_status, c.status AS class_status,
               CASE WHEN a.deleted_at IS NULL THEN a.id END AS attendance_id,
               a.id AS stored_attendance_id
        FROM enrollments e
        JOIN sessions se ON se.id = ?
        JOIN classes c ON c.id = se.class_id
        LEFT JOIN attendance a ON a.enrollment_id = e.id AND a.session_id = se.id
        WHERE e.id = ?
        ''',
        [sessionId, enrollmentId],
      );
      if (rows.isEmpty) {
        throw const LearningDataException('Không tìm thấy buổi học/đăng ký.');
      }
      final row = rows.single;
      if (row['class_id'] != row['session_class_id']) {
        throw const LearningDataException(
          'Học viên không thuộc lớp của buổi học này.',
        );
      }
      if (row['session_status'] == 'cancelled') {
        throw const LearningDataException('Buổi học đã bị hủy.');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final completedClass = row['class_status'] == 'completed';
      if (completedClass) {
        if (role != 'admin' ||
            row['attendance_id'] == null ||
            (correctionReason?.trim().isEmpty ?? true)) {
          throw const LearningDataException(
            'Sau khi lớp hoàn thành, chỉ admin được sửa điểm danh đã có và phải nhập lý do.',
          );
        }
      } else {
        if (row['class_status'] != 'ongoing' ||
            (row['start_at'] as int) > now) {
          throw const LearningDataException(
            'Chỉ điểm danh khi lớp đang diễn ra và buổi học đã bắt đầu.',
          );
        }
        if (row['enrollment_status'] != 'enrolled' ||
            (row['enrolled_at'] as int) > (row['start_at'] as int)) {
          throw const LearningDataException(
            'Học viên chưa có đăng ký hợp lệ tại thời điểm buổi học.',
          );
        }
      }

      final storedAttendanceId = row['stored_attendance_id'];
      final values = {
        'status': status,
        'note': note.trim(),
        'updated_at': now,
        'correction_reason': completedClass ? correctionReason?.trim() : null,
        'deleted_at': null,
      };
      if (storedAttendanceId == null) {
        await txn.insert('attendance', {
          'enrollment_id': enrollmentId,
          'session_id': sessionId,
          ...values,
        });
      } else {
        await txn.update(
          'attendance',
          values,
          where: 'id = ?',
          whereArgs: [storedAttendanceId],
        );
      }
    });
  }

  Future<void> deleteAttendance({
    required int enrollmentId,
    required int sessionId,
    required String role,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw const LearningDataException('Cần nhập lý do xóa điểm danh.');
    }
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        '''
        SELECT e.class_id, e.status AS enrollment_status, se.class_id AS session_class_id,
               se.status AS session_status, se.start_at, c.status AS class_status,
               a.id AS attendance_id
        FROM enrollments e
        JOIN sessions se ON se.id = ?
        JOIN classes c ON c.id = se.class_id
        LEFT JOIN attendance a ON a.enrollment_id = e.id AND a.session_id = se.id
          AND a.deleted_at IS NULL
        WHERE e.id = ?
        ''',
        [sessionId, enrollmentId],
      );
      if (rows.isEmpty ||
          rows.single['attendance_id'] == null ||
          rows.single['class_id'] != rows.single['session_class_id']) {
        throw const LearningDataException('Không tìm thấy điểm danh hợp lệ.');
      }
      final row = rows.single;
      final completedClass = row['class_status'] == 'completed';
      if (row['session_status'] == 'cancelled') {
        throw const LearningDataException('Buổi học đã bị hủy.');
      }
      if (completedClass) {
        if (role != 'admin') {
          throw const LearningDataException(
            'Chỉ admin được xóa điểm danh sau khi lớp hoàn thành.',
          );
        }
      } else if (row['class_status'] != 'ongoing' ||
          (row['start_at'] as int) > DateTime.now().millisecondsSinceEpoch) {
        throw const LearningDataException(
          'Chỉ sửa điểm danh trong lớp đang diễn ra sau giờ bắt đầu.',
        );
      }
      await txn.update(
        'attendance',
        {
          'deleted_at': DateTime.now().millisecondsSinceEpoch,
          'delete_reason': reason.trim(),
        },
        where: 'id = ?',
        whereArgs: [row['attendance_id']],
      );
    });
  }

  Future<void> saveResult({
    required int enrollmentId,
    required double score,
    required String comment,
    required String role,
    String? correctionReason,
  }) async {
    final scaledScore = score * 100;
    if (!score.isFinite ||
        score < 0 ||
        score > 10 ||
        (scaledScore - scaledScore.round()).abs() > 0.000001) {
      throw const LearningDataException(
        'Điểm phải từ 0 đến 10 và tối đa 2 chữ số thập phân.',
      );
    }
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        '''
        SELECT e.status AS enrollment_status, c.status AS class_status,
               CASE WHEN lr.deleted_at IS NULL THEN lr.id END AS result_id,
               lr.id AS stored_result_id
        FROM enrollments e
        JOIN classes c ON c.id = e.class_id
        LEFT JOIN learning_results lr ON lr.enrollment_id = e.id
        WHERE e.id = ?
        ''',
        [enrollmentId],
      );
      if (rows.isEmpty) {
        throw const LearningDataException('Không tìm thấy lượt đăng ký.');
      }
      final row = rows.single;
      final completedClass = row['class_status'] == 'completed';
      if (row['class_status'] == 'cancelled' ||
          row['enrollment_status'] == 'cancelled') {
        throw const LearningDataException(
          'Không thể nhập điểm mới cho lớp hoặc đăng ký đã hủy.',
        );
      }
      if (completedClass) {
        if (role != 'admin' ||
            row['result_id'] == null ||
            (correctionReason?.trim().isEmpty ?? true)) {
          throw const LearningDataException(
            'Sau khi lớp hoàn thành, chỉ admin được sửa kết quả đã có và phải nhập lý do.',
          );
        }
      } else if (row['class_status'] != 'ongoing' ||
          row['enrollment_status'] != 'enrolled') {
        throw const LearningDataException(
          'Chỉ nhập kết quả cho học viên đang học trong lớp đang diễn ra.',
        );
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final storedResultId = row['stored_result_id'];
      final values = {
        'score': score,
        'comment': comment.trim(),
        'updated_at': now,
        'correction_reason': completedClass ? correctionReason?.trim() : null,
        'deleted_at': null,
      };
      if (storedResultId == null) {
        await txn.insert('learning_results', {
          'enrollment_id': enrollmentId,
          ...values,
        });
      } else {
        await txn.update(
          'learning_results',
          values,
          where: 'id = ?',
          whereArgs: [storedResultId],
        );
      }
    });
  }

  Future<void> deleteResult({
    required int enrollmentId,
    required String role,
    required String reason,
  }) async {
    if (role != 'admin') {
      throw const LearningDataException('Chỉ admin được xóa kết quả đã lưu.');
    }
    if (reason.trim().isEmpty) {
      throw const LearningDataException('Cần nhập lý do xóa kết quả.');
    }
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        '''
        SELECT lr.id, lr.deleted_at, c.status AS class_status
        FROM learning_results lr
        JOIN enrollments e ON e.id = lr.enrollment_id
        JOIN classes c ON c.id = e.class_id
        WHERE e.id = ?
        ''',
        [enrollmentId],
      );
      if (rows.isEmpty || rows.single['deleted_at'] != null) {
        throw const LearningDataException('Không tìm thấy kết quả đang lưu.');
      }
      await txn.update(
        'learning_results',
        {
          'deleted_at': DateTime.now().millisecondsSinceEpoch,
          'delete_reason': reason.trim(),
        },
        where: 'id = ?',
        whereArgs: [rows.single['id']],
      );
    });
  }

  ClassRecord _classRecord(Map<String, Object?> row) => ClassRecord(
    id: row['id'] as int,
    code: row['class_code'] as String,
    name: row['name'] as String,
    courseName: row['course_name'] as String,
    teacherName: row['teacher_name'] as String,
    roomName: row['room_name'] as String,
    status: row['status'] as String,
    enrolledCount: row['current_enrollment_count'] as int,
    capacity: row['max_capacity'] as int,
    startDate: DateTime.fromMillisecondsSinceEpoch(row['start_date'] as int),
    endDate: DateTime.fromMillisecondsSinceEpoch(row['end_date'] as int),
    scheduleDetails: row['schedule_details'] as String,
  );

  StudentRecord _studentRecord(Map<String, Object?> row) => StudentRecord(
    id: row['id'] as int,
    code: row['student_code'] as String,
    fullName: row['full_name'] as String,
    email: row['email'] as String,
    phone: row['phone'] as String,
    status: row['status'] as String,
  );

  EnrollmentRecord _enrollmentRecord(Map<String, Object?> row) =>
      EnrollmentRecord(
        id: row['id'] as int,
        studentId: row['student_id'] as int,
        studentCode: row['student_code'] as String,
        studentName: row['student_name'] as String,
        classId: row['class_id'] as int,
        classCode: row['class_code'] as String,
        className: row['class_name'] as String,
        status: row['status'] as String,
        enrolledAt: DateTime.fromMillisecondsSinceEpoch(
          row['enrolled_at'] as int,
        ),
        cancelledAt: row['cancelled_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row['cancelled_at'] as int),
        cancelReason: row['cancel_reason'] as String?,
        score: (row['score'] as num?)?.toDouble(),
        resultComment: row['result_comment'] as String?,
      );

  SessionRecord _sessionRecord(Map<String, Object?> row) => SessionRecord(
    id: row['id'] as int,
    classId: row['class_id'] as int,
    number: row['session_number'] as int,
    title: row['title'] as String,
    startAt: DateTime.fromMillisecondsSinceEpoch(row['start_at'] as int),
    endAt: DateTime.fromMillisecondsSinceEpoch(row['end_at'] as int),
    status: row['status'] as String,
  );
}
