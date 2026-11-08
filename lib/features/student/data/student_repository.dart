import '../../../core/database/database_helper.dart';
import '../models/student.dart';

class StudentDataException implements Exception {
  const StudentDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StudentRepository {
  StudentRepository(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  // ── List & Search ───────────────────────────────────────────────

  Future<List<Student>> students({String? statusFilter}) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'students',
      where: (statusFilter != null && statusFilter != 'all')
          ? 'status = ?'
          : null,
      whereArgs: (statusFilter != null && statusFilter != 'all')
          ? [statusFilter]
          : null,
      orderBy: 'full_name COLLATE NOCASE',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<List<Student>> search(String query, {String? statusFilter}) async {
    final db = await _databaseHelper.database;
    final q = '%${query.trim()}%';

    String? where;
    List<Object?> whereArgs = [];

    if (query.trim().isNotEmpty &&
        statusFilter != null &&
        statusFilter != 'all') {
      where =
          '(student_code LIKE ? OR full_name LIKE ? OR email LIKE ? OR phone LIKE ?) AND status = ?';
      whereArgs = [q, q, q, q, statusFilter];
    } else if (query.trim().isNotEmpty) {
      where = 'student_code LIKE ? OR full_name LIKE ? OR email LIKE ? OR phone LIKE ?';
      whereArgs = [q, q, q, q];
    } else if (statusFilter != null && statusFilter != 'all') {
      where = 'status = ?';
      whereArgs = [statusFilter];
    }

    final rows = await db.query(
      'students',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'full_name COLLATE NOCASE',
      limit: 200,
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<Student?> studentById(int id) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.single);
  }

  Future<Student?> studentByCode(String code) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'students',
      where: 'student_code = ?',
      whereArgs: [code.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.single);
  }

  // ── Create ───────────────────────────────────────────────────────

  Future<int> addStudent({
    required String code,
    required String fullName,
    required String email,
    required String phone,
    required String status,
  }) async {
    _validateFields(
      code: code,
      fullName: fullName,
      email: email,
      phone: phone,
      status: status,
    );

    final db = await _databaseHelper.database;

    // Check duplicate code
    final existing = await db.query(
      'students',
      columns: ['id'],
      where: 'student_code = ?',
      whereArgs: [code.trim().toUpperCase()],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const StudentDataException('Mã học viên đã tồn tại.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert('students', {
      'student_code': code.trim().toUpperCase(),
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'status': status,
      'created_at': now,
    });
  }

  // ── Update ───────────────────────────────────────────────────────

  Future<void> updateStudent({
    required int id,
    required String code,
    required String fullName,
    required String email,
    required String phone,
    required String status,
  }) async {
    _validateFields(
      code: code,
      fullName: fullName,
      email: email,
      phone: phone,
      status: status,
    );

    final db = await _databaseHelper.database;

    // Check if student exists
    final existing = await db.query(
      'students',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) {
      throw const StudentDataException('Không tìm thấy học viên.');
    }

    // Check duplicate code for other students
    final duplicate = await db.query(
      'students',
      columns: ['id'],
      where: 'student_code = ? AND id != ?',
      whereArgs: [code.trim().toUpperCase(), id],
      limit: 1,
    );
    if (duplicate.isNotEmpty) {
      throw const StudentDataException('Mã học viên đã được dùng bởi học viên khác.');
    }

    await db.update(
      'students',
      {
        'student_code': code.trim().toUpperCase(),
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'status': status,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Delete ───────────────────────────────────────────────────────

  Future<void> deleteStudent(int id) async {
    final db = await _databaseHelper.database;

    // Verify student exists
    final student = await studentById(id);
    if (student == null) {
      throw const StudentDataException('Không tìm thấy học viên để xóa.');
    }

    // Verify no enrollment records exist at all (SRS UC06)
    final enrollments = await db.query(
      'enrollments',
      columns: ['id'],
      where: 'student_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (enrollments.isNotEmpty) {
      throw const StudentDataException(
        'Học viên đã có lịch sử đăng ký học, không thể xóa để bảo toàn dữ liệu. Bạn có thể chuyển trạng thái học viên sang Ngưng hoạt động (inactive).',
      );
    }

    final count = await db.delete('students', where: 'id = ?', whereArgs: [id]);
    if (count == 0) {
      throw const StudentDataException('Không tìm thấy học viên để xóa.');
    }
  }

  // ── Status Change (SRS UC06, UC10) ───────────────────────────────

  Future<void> changeStudentStatus({
    required int id,
    required String newStatus,
  }) async {
    if (!Student.validStatuses.contains(newStatus)) {
      throw const StudentDataException('Trạng thái không hợp lệ.');
    }
    final db = await _databaseHelper.database;
    final student = await studentById(id);
    if (student == null) {
      throw const StudentDataException('Không tìm thấy học viên.');
    }

    // When deactivating, verify no active enrollments in planned, open, or ongoing classes
    if (newStatus == 'inactive' || newStatus == 'dropped') {
      final activeClasses = await db.rawQuery(
        '''
        SELECT c.class_code, c.name, c.status
        FROM enrollments e
        JOIN classes c ON c.id = e.class_id
        WHERE e.student_id = ? AND e.status = 'enrolled'
          AND c.status IN ('planned', 'open', 'ongoing')
        LIMIT 1
        ''',
        [id],
      );
      if (activeClasses.isNotEmpty) {
        final row = activeClasses.first;
        throw StudentDataException(
          'Không thể chuyển trạng thái vì học viên đang có lớp ${row['class_code']} '
          '(${row['name']}) ở trạng thái "${row['status']}". Hãy hủy đăng ký trước.',
        );
      }
    }

    await db.update(
      'students',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Associated Class Enrollments (SRS UC07) ──────────────────────

  Future<List<Map<String, Object?>>> studentEnrollmentDetails(int studentId) async {
    final db = await _databaseHelper.database;
    return db.rawQuery(
      '''
      SELECT e.id AS enrollment_id, e.status AS enrollment_status, e.enrolled_at,
             c.class_code, c.name AS class_name, c.status AS class_status,
             co.name AS course_name,
             lr.score, lr.comment AS result_comment
      FROM enrollments e
      JOIN classes c ON c.id = e.class_id
      JOIN course co ON co.id = c.course_id
      LEFT JOIN learning_results lr ON lr.enrollment_id = e.id AND lr.deleted_at IS NULL
      WHERE e.student_id = ?
      ORDER BY e.enrolled_at DESC
      ''',
      [studentId],
    );
  }

  // ── Auto-generate code ────────────────────────────────────────────

  Future<String> generateNextCode() async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      "SELECT student_code FROM students ORDER BY student_code DESC LIMIT 1",
    );
    if (rows.isEmpty) return 'STU0001';
    final last = rows.single['student_code'] as String;
    final num = int.tryParse(last.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 'STU${(num + 1).toString().padLeft(4, '0')}';
  }

  // ── Helpers ──────────────────────────────────────────────────────

  void _validateFields({
    required String code,
    required String fullName,
    required String email,
    required String phone,
    required String status,
  }) {
    if (code.trim().isEmpty) {
      throw const StudentDataException('Vui lòng nhập mã học viên.');
    }
    if (fullName.trim().isEmpty) {
      throw const StudentDataException('Vui lòng nhập họ tên học viên.');
    }
    if (email.trim().isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      throw const StudentDataException('Email không hợp lệ.');
    }
    if (phone.trim().isNotEmpty &&
        !RegExp(r'^[0-9+\-\s]{7,15}$').hasMatch(phone.trim())) {
      throw const StudentDataException('Số điện thoại không hợp lệ.');
    }
    if (!Student.validStatuses.contains(status)) {
      throw const StudentDataException('Trạng thái không hợp lệ.');
    }
  }

  Student _fromRow(Map<String, Object?> row) => Student(
    id: row['id'] as int,
    code: row['student_code'] as String,
    fullName: row['full_name'] as String,
    email: row['email'] as String,
    phone: row['phone'] as String,
    status: row['status'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
  );
}
