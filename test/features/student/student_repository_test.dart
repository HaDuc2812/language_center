import 'package:flutter_test/flutter_test.dart';
import 'package:language_center/core/database/database_helper.dart';
import 'package:language_center/features/student/data/student_repository.dart';
import 'package:language_center/features/student/models/student.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper helper;
  late StudentRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    helper = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await helper.database;
    repository = StudentRepository(helper);
  });

  tearDown(() async {
    await helper.close();
  });

  test('seed provides initial student records', () async {
    final list = await repository.students();
    expect(list.length, greaterThanOrEqualTo(3));
    expect(list.map((s) => s.code), containsAll(['STU0001', 'STU0002', 'STU0003']));
  });

  test('adds a valid student successfully', () async {
    final id = await repository.addStudent(
      code: 'STU0099',
      fullName: 'Vũ Minh Tuấn',
      email: 'tuan.vu@example.com',
      phone: '0912345678',
      status: 'studying',
    );
    expect(id, isPositive);

    final student = await repository.studentById(id);
    expect(student, isNotNull);
    expect(student!.code, 'STU0099');
    expect(student.fullName, 'Vũ Minh Tuấn');
    expect(student.email, 'tuan.vu@example.com');
    expect(student.phone, '0912345678');
    expect(student.status, 'studying');
  });

  test('rejects duplicate student code', () async {
    await expectLater(
      repository.addStudent(
        code: 'STU0001',
        fullName: 'Trùng mã',
        email: 'trung@example.com',
        phone: '0988888888',
        status: 'studying',
      ),
      throwsA(isA<StudentDataException>()),
    );
  });

  test('validates input fields (empty name, invalid email, invalid phone)', () async {
    // Empty full name
    await expectLater(
      repository.addStudent(
        code: 'STU0050',
        fullName: '  ',
        email: 'test@example.com',
        phone: '0901112222',
        status: 'studying',
      ),
      throwsA(isA<StudentDataException>()),
    );

    // Invalid email
    await expectLater(
      repository.addStudent(
        code: 'STU0051',
        fullName: 'Học viên A',
        email: 'not-an-email',
        phone: '0901112222',
        status: 'studying',
      ),
      throwsA(isA<StudentDataException>()),
    );

    // Invalid phone
    await expectLater(
      repository.addStudent(
        code: 'STU0052',
        fullName: 'Học viên B',
        email: 'b@example.com',
        phone: 'abc123',
        status: 'studying',
      ),
      throwsA(isA<StudentDataException>()),
    );
  });

  test('searches students by query and status filter', () async {
    final byName = await repository.search('Nguyễn');
    expect(byName.map((s) => s.fullName), contains('Nguyễn Văn A'));

    final byCode = await repository.search('STU0002');
    expect(byCode.map((s) => s.code), contains('STU0002'));

    final byStatus = await repository.search('', statusFilter: 'dropped');
    expect(byStatus.every((s) => s.status == 'dropped'), isTrue);
    expect(byStatus.map((s) => s.code), contains('STU0003'));
  });

  test('updates student profile successfully', () async {
    final student = await repository.studentByCode('STU0002');
    expect(student, isNotNull);

    await repository.updateStudent(
      id: student!.id,
      code: 'STU0002',
      fullName: 'Trần Thị B Updated',
      email: 'b_updated@example.com',
      phone: '0999999999',
      status: 'active',
    );

    final updated = await repository.studentById(student.id);
    expect(updated!.fullName, 'Trần Thị B Updated');
    expect(updated.email, 'b_updated@example.com');
    expect(updated.phone, '0999999999');
    expect(updated.status, 'active');
  });

  test('rejects deleting a student with enrollment history (SRS UC06)', () async {
    final student = await repository.studentByCode('STU0001');
    expect(student, isNotNull);

    // STU0001 is enrolled in IELTS50_01 in seed data
    await expectLater(
      repository.deleteStudent(student!.id),
      throwsA(isA<StudentDataException>()),
    );
  });

  test('allows deleting an unused student record with no enrollment history', () async {
    final id = await repository.addStudent(
      code: 'STU0999',
      fullName: 'Học viên chưa học',
      email: 'unused@example.com',
      phone: '0901239999',
      status: 'active',
    );

    await repository.deleteStudent(id);
    final deleted = await repository.studentById(id);
    expect(deleted, isNull);
  });

  test('blocks deactivation when student has active enrollment in ongoing class', () async {
    final student = await repository.studentByCode('STU0001');
    expect(student, isNotNull);

    // STU0001 is enrolled in ongoing class IELTS50_01
    await expectLater(
      repository.changeStudentStatus(id: student!.id, newStatus: 'inactive'),
      throwsA(isA<StudentDataException>()),
    );
  });

  test('allows changing status when eligible', () async {
    final id = await repository.addStudent(
      code: 'STU0888',
      fullName: 'Học viên tự do',
      email: 'free@example.com',
      phone: '0908888888',
      status: 'studying',
    );

    await repository.changeStudentStatus(id: id, newStatus: 'graduated');
    final updated = await repository.studentById(id);
    expect(updated!.status, 'graduated');
  });

  test('generates next sequential student code', () async {
    final code = await repository.generateNextCode();
    expect(code, startsWith('STU'));
    expect(code, 'STU0004'); // since seed has STU0001..STU0003
  });

  test('fetches student enrollment details (SRS UC07)', () async {
    final student = await repository.studentByCode('STU0001');
    final enrollments = await repository.studentEnrollmentDetails(student!.id);
    expect(enrollments, isNotEmpty);
    expect(enrollments.first['class_code'], 'IELTS50_01');
    expect(enrollments.first['score'], 8.5);
  });
}
