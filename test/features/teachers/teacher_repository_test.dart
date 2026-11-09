import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_center/core/database/database_helper.dart';
import 'package:language_center/features/teachers/models/teacher_model.dart';
import 'package:language_center/features/teachers/repositories/teacher_repository.dart';
import 'package:language_center/features/teachers/repositories/teacher_repository_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late DatabaseHelper helper;
  late TeacherRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    helper = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await helper.database;
    repository = TeacherRepositoryImpl(helper, MockFirebaseFirestore());
  });

  tearDown(() async {
    await helper.close();
  });

  test('createTeacher saves teacher to SQLite database successfully', () async {
    final newTeacher = Teacher(
      id: '',
      code: 'GV999',
      fullName: 'Thầy Nguyễn Văn Nam',
      specialties: ['IELTS', 'TOEIC'],
      email: 'nam.nv@example.com',
      phoneNumber: '0987654321',
      status: TeacherStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repository.createTeacher(newTeacher);

    // Verify it is saved in SQLite database
    final db = await helper.database;
    final rows = await db.query(
      'teachers',
      where: 'teacher_code = ?',
      whereArgs: ['GV999'],
    );

    expect(rows.length, 1);
    expect(rows.first['full_name'], 'Thầy Nguyễn Văn Nam');
    expect(rows.first['specialization'], 'IELTS, TOEIC');
    expect(rows.first['status'], 'active');

    // Verify getTeachers returns the newly created teacher
    final teachers = await repository.getTeachers();
    expect(teachers.any((t) => t.code == 'GV999'), isTrue);
  });

  test('createTeacher rejects duplicate teacher code (BR-01)', () async {
    final teacher1 = Teacher(
      id: '',
      code: 'GV888',
      fullName: 'Cô Lê Thị Hà',
      specialties: ['Giao tiếp'],
      email: 'ha.le@example.com',
      phoneNumber: '0912345678',
      status: TeacherStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repository.createTeacher(teacher1);

    final teacherDuplicate = Teacher(
      id: '',
      code: 'gv888', // lowercase should still be detected as duplicate
      fullName: 'Người khác',
      specialties: ['TOEFL'],
      email: 'other@example.com',
      phoneNumber: '0911111111',
      status: TeacherStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    expect(
      () => repository.createTeacher(teacherDuplicate),
      throwsA(isA<TeacherBusinessException>()),
    );
  });
}
