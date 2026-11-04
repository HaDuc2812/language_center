import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper({DatabaseFactory? factory, this._databasePath})
    : _factory = factory ?? databaseFactory;

  static const databaseName = 'language_center.db';
  static const databaseVersion = 1;

  final DatabaseFactory _factory;
  final String? _databasePath;
  Future<Database>? _databaseFuture;

  Future<Database> get database => _databaseFuture ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final dbPath =
        _databasePath ??
        path.join(await _factory.getDatabasesPath(), databaseName);
    try {
      return await _factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: databaseVersion,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: _createSchema,
          onUpgrade: _upgradeSchema,
          onOpen: (db) => db.execute('PRAGMA foreign_keys = ON'),
        ),
      );
    } catch (_) {
      _databaseFuture = null;
      rethrow;
    }
  }

  Future<void> close() async {
    final opening = _databaseFuture;
    _databaseFuture = null;
    if (opening != null) await (await opening).close();
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.transaction((txn) async {
      await _createTables(txn);
      await _seed(txn);
    });
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 1:
          await _createTables(db);
          await _seed(db);
      }
    }
  }

  Future<void> _createTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_code TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL CHECK(status IN ('studying', 'active', 'dropped', 'graduated', 'inactive')),
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_code TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        specialization TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL CHECK(status IN ('active', 'inactive')),
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS course (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        duration_weeks INTEGER NOT NULL CHECK(duration_weeks > 0),
        status TEXT NOT NULL CHECK(status IN ('active', 'inactive'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS classrooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_name TEXT NOT NULL UNIQUE,
        capacity INTEGER NOT NULL CHECK(capacity > 0),
        status TEXT NOT NULL CHECK(status IN ('active', 'inactive'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        course_id INTEGER NOT NULL REFERENCES course(id) ON DELETE RESTRICT,
        teacher_id INTEGER NOT NULL REFERENCES teachers(id) ON DELETE RESTRICT,
        room_id INTEGER NOT NULL REFERENCES classrooms(id) ON DELETE RESTRICT,
        current_enrollment_count INTEGER NOT NULL DEFAULT 0
          CHECK(current_enrollment_count >= 0 AND current_enrollment_count <= max_capacity),
        max_capacity INTEGER NOT NULL CHECK(max_capacity > 0),
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL CHECK(end_date > start_date),
        schedule_details TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL CHECK(status IN ('planned', 'open', 'ongoing', 'completed', 'cancelled'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
        room_id INTEGER NOT NULL REFERENCES classrooms(id) ON DELETE RESTRICT,
        session_number INTEGER NOT NULL CHECK(session_number > 0),
        title TEXT NOT NULL,
        start_at INTEGER NOT NULL,
        end_at INTEGER NOT NULL CHECK(end_at > start_at),
        status TEXT NOT NULL CHECK(status IN ('planned', 'ongoing', 'completed', 'cancelled')),
        UNIQUE(class_id, session_number)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS enrollments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE RESTRICT,
        class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
        status TEXT NOT NULL CHECK(status IN ('enrolled', 'cancelled')),
        enrolled_at INTEGER NOT NULL,
        cancelled_at INTEGER,
        cancel_reason TEXT,
        UNIQUE(student_id, class_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        enrollment_id INTEGER NOT NULL REFERENCES enrollments(id) ON DELETE RESTRICT,
        session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE RESTRICT,
        status TEXT NOT NULL CHECK(status IN ('present', 'absent', 'late', 'excused')),
        note TEXT NOT NULL DEFAULT '',
        updated_at INTEGER NOT NULL,
        correction_reason TEXT,
        deleted_at INTEGER,
        delete_reason TEXT,
        UNIQUE(enrollment_id, session_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS learning_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        enrollment_id INTEGER NOT NULL UNIQUE REFERENCES enrollments(id) ON DELETE RESTRICT,
        score REAL NOT NULL CHECK(score >= 0 AND score <= 10),
        comment TEXT NOT NULL DEFAULT '',
        updated_at INTEGER NOT NULL,
        correction_reason TEXT,
        deleted_at INTEGER,
        delete_reason TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_enrollments_class ON enrollments(class_id, status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_enrollments_student ON enrollments(student_id, status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sessions_class ON sessions(class_id, start_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attendance_session ON attendance(session_id)',
    );
  }

  Future<void> _seed(DatabaseExecutor db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final yesterday = now - const Duration(days: 1).inMilliseconds;
    final tomorrow = now + const Duration(days: 1).inMilliseconds;
    final monthLater = now + const Duration(days: 30).inMilliseconds;

    await db.insert('students', {
      'student_code': 'STU0001',
      'full_name': 'Nguyễn Văn A',
      'email': 'student1@example.com',
      'phone': '0900000001',
      'status': 'studying',
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('students', {
      'student_code': 'STU0002',
      'full_name': 'Trần Thị B',
      'email': 'student2@example.com',
      'phone': '0900000002',
      'status': 'studying',
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('students', {
      'student_code': 'STU0003',
      'full_name': 'Lê Văn C',
      'email': 'student3@example.com',
      'phone': '0900000003',
      'status': 'dropped',
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('teachers', {
      'teacher_code': 'TEA0001',
      'full_name': 'Cô giáo Sarah',
      'email': 'teacher@example.com',
      'specialization': 'IELTS, Giao tiếp',
      'status': 'active',
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('course', {
      'course_code': 'IELTS_5.0',
      'name': 'Luyện thi IELTS mục tiêu 5.0',
      'description': 'Khóa học căn bản đến trung cấp',
      'duration_weeks': 12,
      'status': 'active',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('classrooms', {
      'room_name': 'Room 302',
      'capacity': 25,
      'status': 'active',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final course = await db.query(
      'course',
      columns: ['id'],
      where: 'course_code = ?',
      whereArgs: ['IELTS_5.0'],
      limit: 1,
    );
    final teacher = await db.query(
      'teachers',
      columns: ['id'],
      where: 'teacher_code = ?',
      whereArgs: ['TEA0001'],
      limit: 1,
    );
    final room = await db.query(
      'classrooms',
      columns: ['id'],
      where: 'room_name = ?',
      whereArgs: ['Room 302'],
      limit: 1,
    );
    final courseId = course.single['id'] as int;
    final teacherId = teacher.single['id'] as int;
    final roomId = room.single['id'] as int;

    await db.insert('classes', {
      'class_code': 'IELTS50_01',
      'name': 'IELTS 5.0 - Ca tối',
      'course_id': courseId,
      'teacher_id': teacherId,
      'room_id': roomId,
      'current_enrollment_count': 0,
      'max_capacity': 20,
      'start_date': yesterday,
      'end_date': monthLater,
      'schedule_details': 'Thứ 2 - 4 - 6 (18:00 - 20:00)',
      'status': 'ongoing',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('classes', {
      'class_code': 'IELTS50_FULL',
      'name': 'IELTS 5.0 - Đã đủ chỗ',
      'course_id': courseId,
      'teacher_id': teacherId,
      'room_id': roomId,
      'current_enrollment_count': 1,
      'max_capacity': 1,
      'start_date': yesterday,
      'end_date': monthLater,
      'schedule_details': 'Thứ 3 - 5 (18:00 - 20:00)',
      'status': 'ongoing',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('classes', {
      'class_code': 'IELTS50_OPEN',
      'name': 'IELTS 5.0 - Đang nhận học viên',
      'course_id': courseId,
      'teacher_id': teacherId,
      'room_id': roomId,
      'current_enrollment_count': 0,
      'max_capacity': 12,
      'start_date': tomorrow,
      'end_date': monthLater,
      'schedule_details': 'Thứ 3 - 5 (18:00 - 20:00)',
      'status': 'open',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('classes', {
      'class_code': 'IELTS50_DONE',
      'name': 'IELTS 5.0 - Đã hoàn thành',
      'course_id': courseId,
      'teacher_id': teacherId,
      'room_id': roomId,
      'current_enrollment_count': 0,
      'max_capacity': 15,
      'start_date': yesterday,
      'end_date': yesterday + const Duration(days: 1).inMilliseconds,
      'schedule_details': 'Thứ 7 (09:00 - 12:00)',
      'status': 'completed',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final ongoingClass = await db.query(
      'classes',
      columns: ['id'],
      where: 'class_code = ?',
      whereArgs: ['IELTS50_01'],
      limit: 1,
    );
    final fullClass = await db.query(
      'classes',
      columns: ['id'],
      where: 'class_code = ?',
      whereArgs: ['IELTS50_FULL'],
      limit: 1,
    );
    final student1 = await db.query(
      'students',
      columns: ['id'],
      where: 'student_code = ?',
      whereArgs: ['STU0001'],
      limit: 1,
    );
    final student2 = await db.query(
      'students',
      columns: ['id'],
      where: 'student_code = ?',
      whereArgs: ['STU0002'],
      limit: 1,
    );
    final ongoingClassId = ongoingClass.single['id'] as int;
    final fullClassId = fullClass.single['id'] as int;
    final student1Id = student1.single['id'] as int;
    final student2Id = student2.single['id'] as int;
    await db.insert('enrollments', {
      'student_id': student1Id,
      'class_id': ongoingClassId,
      'status': 'enrolled',
      'enrolled_at': yesterday,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('enrollments', {
      'student_id': student2Id,
      'class_id': fullClassId,
      'status': 'enrolled',
      'enrolled_at': yesterday,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.update(
      'classes',
      {'current_enrollment_count': 1},
      where: 'id = ? AND current_enrollment_count = 0',
      whereArgs: [ongoingClassId],
    );

    await db.insert('sessions', {
      'class_id': ongoingClassId,
      'room_id': roomId,
      'session_number': 1,
      'title': 'Buổi 1 - Giới thiệu',
      'start_at': yesterday,
      'end_at': yesterday + const Duration(hours: 2).inMilliseconds,
      'status': 'ongoing',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('sessions', {
      'class_id': ongoingClassId,
      'room_id': roomId,
      'session_number': 2,
      'title': 'Buổi 2 - Ngữ pháp',
      'start_at': tomorrow,
      'end_at': tomorrow + const Duration(hours: 2).inMilliseconds,
      'status': 'planned',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final enrollment = await db.query(
      'enrollments',
      columns: ['id'],
      where: 'student_id = ? AND class_id = ?',
      whereArgs: [student1Id, ongoingClassId],
      limit: 1,
    );
    final session = await db.query(
      'sessions',
      columns: ['id'],
      where: 'class_id = ? AND session_number = 1',
      whereArgs: [ongoingClassId],
      limit: 1,
    );
    await db.insert('attendance', {
      'enrollment_id': enrollment.single['id'],
      'session_id': session.single['id'],
      'status': 'present',
      'note': 'Dữ liệu mẫu',
      'updated_at': yesterday,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('learning_results', {
      'enrollment_id': enrollment.single['id'],
      'score': 8.5,
      'comment': 'Làm tốt phần thực hành.',
      'updated_at': yesterday,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
