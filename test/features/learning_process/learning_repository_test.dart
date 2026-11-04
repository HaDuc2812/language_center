import 'package:flutter_test/flutter_test.dart';
import 'package:language_center/core/database/database_helper.dart';
import 'package:language_center/features/learning_process/data/learning_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper helper;
  late LearningRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    helper = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await helper.database;
    repository = LearningRepository(helper);
  });

  tearDown(() async {
    await helper.close();
  });

  Future<int> classId(String code) async {
    final db = await helper.database;
    final rows = await db.query(
      'classes',
      columns: ['id'],
      where: 'class_code = ?',
      whereArgs: [code],
      limit: 1,
    );
    return rows.single['id'] as int;
  }

  Future<int> enrollmentId(String studentCode, String classCode) async {
    final db = await helper.database;
    final rows = await db.rawQuery(
      '''
      SELECT e.id FROM enrollments e
      JOIN students s ON s.id = e.student_id
      JOIN classes c ON c.id = e.class_id
      WHERE s.student_code = ? AND c.class_code = ?
      ''',
      [studentCode, classCode],
    );
    return rows.single['id'] as int;
  }

  test('seed provides reference data and learning history', () async {
    final classes = await repository.classes();
    expect(classes.map((item) => item.code), contains('IELTS50_01'));
    expect(classes.map((item) => item.code), contains('IELTS50_FULL'));

    final enrollment = await repository.enrollments();
    expect(enrollment, isNotEmpty);
    expect(enrollment.first.studentCode, isNotEmpty);
  });

  test('creates the next session using the class room', () async {
    final id = await classId('IELTS50_01');
    final start = DateTime.now().add(const Duration(minutes: 1));
    final sessionId = await repository.createSession(
      classId: id,
      title: 'Buổi kiểm thử',
      startAt: start,
      endAt: start.add(const Duration(hours: 2)),
      role: 'staff',
    );

    final db = await helper.database;
    final rows = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    expect(rows.single['session_number'], 3);
    expect(rows.single['room_id'], isNotNull);
    expect(rows.single['title'], 'Buổi kiểm thử');
    expect(rows.single['status'], 'planned');
  });

  test('rejects invalid session time, role, and class status', () async {
    final id = await classId('IELTS50_01');
    final start = DateTime.now();
    await expectLater(
      repository.createSession(
        classId: id,
        title: 'Buổi sai giờ',
        startAt: start,
        endAt: start,
        role: 'staff',
      ),
      throwsA(isA<LearningDataException>()),
    );
    await expectLater(
      repository.createSession(
        classId: id,
        title: 'Buổi sai quyền',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        role: 'teacher',
      ),
      throwsA(isA<LearningDataException>()),
    );
    await expectLater(
      repository.createSession(
        classId: await classId('IELTS50_OPEN'),
        title: 'Buổi lớp chưa diễn ra',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        role: 'admin',
      ),
      throwsA(isA<LearningDataException>()),
    );
  });

  test('enrolls a student and increases class count atomically', () async {
    await repository.enroll(
      studentCode: 'STU0002',
      classId: await classId('IELTS50_01'),
    );

    final db = await helper.database;
    final rows = await db.query(
      'classes',
      columns: ['current_enrollment_count'],
      where: 'class_code = ?',
      whereArgs: ['IELTS50_01'],
    );
    expect(rows.single['current_enrollment_count'], 2);
    expect(
      (await repository.enrollments(
        classId: await classId('IELTS50_01'),
      )).map((item) => item.studentCode),
      contains('STU0002'),
    );
  });

  test('rejects duplicate enrollment and keeps count unchanged', () async {
    final id = await classId('IELTS50_01');
    await expectLater(
      repository.enroll(studentCode: 'STU0001', classId: id),
      throwsA(isA<LearningDataException>()),
    );
    final db = await helper.database;
    final rows = await db.query(
      'classes',
      columns: ['current_enrollment_count'],
      where: 'id = ?',
      whereArgs: [id],
    );
    expect(rows.single['current_enrollment_count'], 1);
  });

  test('rejects enrollment into a full class', () async {
    await expectLater(
      repository.enroll(
        studentCode: 'STU0001',
        classId: await classId('IELTS50_FULL'),
      ),
      throwsA(isA<LearningDataException>()),
    );
  });

  test('two enrollments competing for last seat allow only one', () async {
    final id = await classId('IELTS50_01');
    final db = await helper.database;
    await db.update(
      'classes',
      {'current_enrollment_count': 19, 'max_capacity': 20},
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.insert('students', {
      'student_code': 'STU0004',
      'full_name': 'Phạm Văn D',
      'email': 'student4@example.com',
      'phone': '0900000004',
      'status': 'studying',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    Future<bool> tryEnroll(String studentCode) async {
      try {
        await repository.enroll(studentCode: studentCode, classId: id);
        return true;
      } on LearningDataException {
        return false;
      }
    }

    final outcomes = await Future.wait([
      tryEnroll('STU0002'),
      tryEnroll('STU0004'),
    ]);
    expect(outcomes.where((success) => success), hasLength(1));
    final classRow = await db.query(
      'classes',
      columns: ['current_enrollment_count'],
      where: 'id = ?',
      whereArgs: [id],
    );
    expect(classRow.single['current_enrollment_count'], 20);
  });

  test('cancelling enrollment decrements count exactly once', () async {
    final id = await enrollmentId('STU0001', 'IELTS50_01');
    await repository.cancelEnrollment(
      enrollmentId: id,
      reason: 'Học viên xin nghỉ.',
    );
    await expectLater(
      repository.cancelEnrollment(enrollmentId: id, reason: 'Hủy lần nữa'),
      throwsA(isA<LearningDataException>()),
    );

    final db = await helper.database;
    final rows = await db.query(
      'classes',
      columns: ['current_enrollment_count'],
      where: 'class_code = ?',
      whereArgs: ['IELTS50_01'],
    );
    expect(rows.single['current_enrollment_count'], 0);

    final studentRows = await db.query(
      'students',
      columns: ['id'],
      where: 'student_code = ?',
      whereArgs: ['STU0001'],
    );
    final history = await repository.studentHistory(
      studentRows.single['id'] as int,
    );
    expect(history, hasLength(1));
    expect(history.single.enrollment.status, 'cancelled');
    expect(history.single.attendances, isNotEmpty);
    expect(history.single.enrollment.score, 8.5);
  });

  test('attendance rejects an enrollment from another class', () async {
    final db = await helper.database;
    final sessions = await db.query(
      'sessions',
      columns: ['id'],
      where: 'session_number = 1',
      limit: 1,
    );
    await expectLater(
      repository.saveAttendance(
        enrollmentId: await enrollmentId('STU0002', 'IELTS50_FULL'),
        sessionId: sessions.single['id'] as int,
        status: 'present',
        note: '',
        role: 'staff',
      ),
      throwsA(isA<LearningDataException>()),
    );
  });

  test('attendance edit updates the existing enrollment-session row', () async {
    final db = await helper.database;
    final session = await db.query(
      'sessions',
      columns: ['id'],
      where: 'session_number = 1',
      limit: 1,
    );
    final sessionId = session.single['id'] as int;
    final enrollment = await enrollmentId('STU0001', 'IELTS50_01');

    await repository.saveAttendance(
      enrollmentId: enrollment,
      sessionId: sessionId,
      status: 'late',
      note: 'Đến muộn 5 phút.',
      role: 'staff',
    );
    final rows = await db.query(
      'attendance',
      where: 'enrollment_id = ? AND session_id = ?',
      whereArgs: [enrollment, sessionId],
    );
    expect(rows, hasLength(1));
    expect(rows.single['status'], 'late');
  });

  test(
    'deleting attendance returns it to not recorded and keeps audit reason',
    () async {
      final db = await helper.database;
      final session = await db.query(
        'sessions',
        columns: ['id'],
        where: 'session_number = 1',
        limit: 1,
      );
      final sessionId = session.single['id'] as int;
      final enrollment = await enrollmentId('STU0001', 'IELTS50_01');

      await repository.deleteAttendance(
        enrollmentId: enrollment,
        sessionId: sessionId,
        role: 'staff',
        reason: 'Nhập nhầm học viên.',
      );
      final visible = await repository.attendance(sessionId);
      final student = visible.singleWhere(
        (record) => record.enrollmentId == enrollment,
      );
      expect(student.status, isNull);

      final stored = await db.query(
        'attendance',
        where: 'enrollment_id = ? AND session_id = ?',
        whereArgs: [enrollment, sessionId],
      );
      expect(stored.single['delete_reason'], 'Nhập nhầm học viên.');
    },
  );

  test('results validate score and preserve zero as a saved score', () async {
    final classIdValue = await classId('IELTS50_01');
    await repository.enroll(studentCode: 'STU0002', classId: classIdValue);
    final enrollment = await enrollmentId('STU0002', 'IELTS50_01');
    await expectLater(
      repository.saveResult(
        enrollmentId: enrollment,
        score: 10.01,
        comment: '',
        role: 'staff',
      ),
      throwsA(isA<LearningDataException>()),
    );
    await repository.saveResult(
      enrollmentId: enrollment,
      score: 0,
      comment: 'Chưa đạt.',
      role: 'staff',
    );

    final db = await helper.database;
    final rows = await db.query(
      'learning_results',
      where: 'enrollment_id = ?',
      whereArgs: [enrollment],
    );
    expect(rows, hasLength(1));
    expect(rows.single['score'], 0);
  });

  test('completed result correction requires admin and a reason', () async {
    final enrollment = await enrollmentId('STU0001', 'IELTS50_01');
    final db = await helper.database;
    await db.update(
      'classes',
      {'status': 'completed'},
      where: 'class_code = ?',
      whereArgs: ['IELTS50_01'],
    );

    await expectLater(
      repository.saveResult(
        enrollmentId: enrollment,
        score: 9,
        comment: '',
        role: 'staff',
      ),
      throwsA(isA<LearningDataException>()),
    );
    await expectLater(
      repository.saveResult(
        enrollmentId: enrollment,
        score: 9,
        comment: '',
        role: 'admin',
      ),
      throwsA(isA<LearningDataException>()),
    );
    await repository.saveResult(
      enrollmentId: enrollment,
      score: 9,
      comment: 'Đã điều chỉnh.',
      role: 'admin',
      correctionReason: 'Sửa theo biên bản.',
    );
  });

  test(
    'result can be soft-deleted by admin and restored without duplicate',
    () async {
      final enrollment = await enrollmentId('STU0001', 'IELTS50_01');
      final db = await helper.database;
      await expectLater(
        repository.deleteResult(
          enrollmentId: enrollment,
          role: 'staff',
          reason: 'Yêu cầu sửa.',
        ),
        throwsA(isA<LearningDataException>()),
      );
      await repository.deleteResult(
        enrollmentId: enrollment,
        role: 'admin',
        reason: 'Nhập nhầm kết quả.',
      );
      var rows = await db.query(
        'learning_results',
        where: 'enrollment_id = ?',
        whereArgs: [enrollment],
      );
      expect(rows, hasLength(1));
      expect(rows.single['deleted_at'], isNotNull);

      await repository.saveResult(
        enrollmentId: enrollment,
        score: 7.5,
        comment: 'Đã nhập lại.',
        role: 'staff',
      );
      rows = await db.query(
        'learning_results',
        where: 'enrollment_id = ?',
        whereArgs: [enrollment],
      );
      expect(rows, hasLength(1));
      expect(rows.single['deleted_at'], isNull);
      expect(rows.single['delete_reason'], 'Nhập nhầm kết quả.');
    },
  );
}
