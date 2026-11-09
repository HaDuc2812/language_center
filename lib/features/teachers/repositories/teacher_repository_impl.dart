import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/firebase_providers.dart';
import '../models/teacher_model.dart';
import 'teacher_repository.dart';

/// Triển khai TeacherRepository kết hợp cơ sở dữ liệu SQLite local (DatabaseHelper)
/// và đồng bộ Cloud Firestore, đảm bảo dữ liệu luôn được lưu thực sự vào database.
class TeacherRepositoryImpl implements TeacherRepository {
  final DatabaseHelper _databaseHelper;
  final FirebaseFirestore _firestore;

  final _changeNotifier = StreamController<void>.broadcast();

  TeacherRepositoryImpl(this._databaseHelper, this._firestore);

  CollectionReference<Map<String, dynamic>> get _firestoreTeachersCol =>
      _firestore.collection('teachers');

  void _notifyChanges() {
    if (!_changeNotifier.isClosed) {
      _changeNotifier.add(null);
    }
  }

  /// Chuyển đổi dữ liệu bản ghi từ bảng `teachers` của SQLite sang đối tượng `Teacher`
  Teacher _fromSqliteRow(Map<String, dynamic> row) {
    final rawSpec = row['specialization'] as String? ?? '';
    final specs = rawSpec
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final createdAtMs =
        row['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final createdAtDate = DateTime.fromMillisecondsSinceEpoch(createdAtMs);

    return Teacher(
      id: row['id'].toString(),
      code: (row['teacher_code'] as String? ?? '').trim(),
      fullName: (row['full_name'] as String? ?? '').trim(),
      specialties: specs,
      email: (row['email'] as String? ?? '').trim(),
      phoneNumber: (row['phone'] as String? ?? '').trim(),
      status: TeacherStatus.fromString(row['status'] as String?),
      createdAt: createdAtDate,
      updatedAt: createdAtDate,
      accountUid: row['account_uid'] as String?,
    );
  }

  @override
  Stream<List<Teacher>> getTeachersStream() async* {
    yield await getTeachers();
    yield* _changeNotifier.stream.asyncMap((_) => getTeachers());
  }

  @override
  Future<List<Teacher>> getTeachers() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'teachers',
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(_fromSqliteRow).toList();
  }

  @override
  Future<Teacher?> getTeacherById(String id) async {
    final db = await _databaseHelper.database;
    final intId = int.tryParse(id);

    final List<Map<String, dynamic>> rows;
    if (intId != null) {
      rows = await db.query(
        'teachers',
        where: 'id = ?',
        whereArgs: [intId],
        limit: 1,
      );
    } else {
      rows = await db.query(
        'teachers',
        where: 'teacher_code = ?',
        whereArgs: [id.trim().toUpperCase()],
        limit: 1,
      );
    }

    if (rows.isEmpty) return null;
    return _fromSqliteRow(rows.first);
  }

  @override
  Future<void> createTeacher(Teacher teacher) async {
    final normalizedCode = teacher.code.trim().toUpperCase();
    final db = await _databaseHelper.database;

    // RÀNG BUỘC 1: Kiểm tra mã giáo viên đã tồn tại chưa trong SQLite
    final duplicateQuery = await db.query(
      'teachers',
      columns: ['id'],
      where: 'teacher_code = ?',
      whereArgs: [normalizedCode],
      limit: 1,
    );

    if (duplicateQuery.isNotEmpty) {
      throw TeacherBusinessException(
        'Mã giáo viên "$normalizedCode" đã tồn tại trong hệ thống. Vui lòng chọn mã khác.',
      );
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. LƯU THỰC SỰ VÀO DATABASE SQLITE LOCAL
    final insertedId = await db.insert(
      'teachers',
      {
        'teacher_code': normalizedCode,
        'full_name': teacher.fullName.trim(),
        'email': teacher.email.trim(),
        'phone': teacher.phoneNumber.trim(),
        'specialization': teacher.specialties.join(', '),
        'status': teacher.status.value,
        'created_at': nowMs,
      },
    );

    // 2. ĐỒNG BỘ LÊN CLOUD FIRESTORE (NẾU CÓ MẠNG & QUYỀN TRUY CẬP)
    try {
      final docRef = _firestoreTeachersCol.doc(insertedId.toString());
      await docRef.set({
        'id': insertedId.toString(),
        'code': normalizedCode,
        'fullName': teacher.fullName.trim(),
        'specialties': teacher.specialties,
        'email': teacher.email.trim(),
        'phoneNumber': teacher.phoneNumber.trim(),
        'status': teacher.status.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (teacher.accountUid != null) 'accountUid': teacher.accountUid,
      });
    } catch (_) {
      // Bỏ qua lỗi Firestore nếu đang offline hoặc phân quyền chưa mở,
      // đảm bảo dữ liệu luôn được lưu an toàn trong database SQLite của ứng dụng.
    }

    _notifyChanges();
  }

  @override
  Future<void> updateTeacher(Teacher teacher) async {
    final db = await _databaseHelper.database;
    final intId = int.tryParse(teacher.id);

    final existing = await db.query(
      'teachers',
      columns: ['id'],
      where: intId != null ? 'id = ?' : 'teacher_code = ?',
      whereArgs: [intId ?? teacher.code.trim().toUpperCase()],
      limit: 1,
    );

    if (existing.isEmpty) {
      throw const TeacherBusinessException(
        'Không tìm thấy thông tin giáo viên để cập nhật.',
      );
    }

    // RÀNG BUỘC 2: Không cho phép sửa 'teacher_code' và 'created_at' khi Update
    await db.update(
      'teachers',
      {
        'full_name': teacher.fullName.trim(),
        'email': teacher.email.trim(),
        'phone': teacher.phoneNumber.trim(),
        'specialization': teacher.specialties.join(', '),
        'status': teacher.status.value,
      },
      where: intId != null ? 'id = ?' : 'teacher_code = ?',
      whereArgs: [intId ?? teacher.code.trim().toUpperCase()],
    );

    // Đồng bộ cập nhật lên Firestore
    try {
      final docRef = _firestoreTeachersCol.doc(teacher.id);
      await docRef.set({
        'fullName': teacher.fullName.trim(),
        'specialties': teacher.specialties,
        'email': teacher.email.trim(),
        'phoneNumber': teacher.phoneNumber.trim(),
        'status': teacher.status.value,
        'updatedAt': FieldValue.serverTimestamp(),
        if (teacher.accountUid != null) 'accountUid': teacher.accountUid,
      }, SetOptions(merge: true));
    } catch (_) {}

    _notifyChanges();
  }

  @override
  Future<void> deleteTeacher(String teacherId) async {
    final db = await _databaseHelper.database;
    final intId = int.tryParse(teacherId);

    // RÀNG BUỘC 3: Trước khi xóa, kiểm tra bảng `classes` xem có lớp nào gắn teacher_id này không
    if (intId != null) {
      final assignedClasses = await db.query(
        'classes',
        columns: ['id'],
        where: 'teacher_id = ?',
        whereArgs: [intId],
        limit: 1,
      );

      if (assignedClasses.isNotEmpty) {
        throw const TeacherBusinessException(
          'Không thể xóa giáo viên này vì đã được phân công lớp học trong hệ thống. '
          'Vui lòng chuyển trạng thái sang "Ngưng hoạt động" (inactive) thay vì xóa.',
        );
      }

      await db.delete(
        'teachers',
        where: 'id = ?',
        whereArgs: [intId],
      );
    } else {
      await db.delete(
        'teachers',
        where: 'teacher_code = ?',
        whereArgs: [teacherId.trim().toUpperCase()],
      );
    }

    try {
      await _firestoreTeachersCol.doc(teacherId).delete();
    } catch (_) {}

    _notifyChanges();
  }

  @override
  Future<void> updateTeacherStatus(
    String teacherId,
    TeacherStatus status,
  ) async {
    final db = await _databaseHelper.database;
    final intId = int.tryParse(teacherId);

    // RÀNG BUỘC 4: Khi chuyển sang inactive, kiểm tra lớp đang phụ trách có trạng thái Planned, Open hoặc Ongoing
    if (status == TeacherStatus.inactive && intId != null) {
      final activeClasses = await db.query(
        'classes',
        columns: ['id'],
        where: 'teacher_id = ? AND LOWER(status) IN (?, ?, ?)',
        whereArgs: [intId, 'planned', 'open', 'ongoing'],
        limit: 1,
      );

      if (activeClasses.isNotEmpty) {
        throw const TeacherBusinessException(
          'Không thể ngưng hoạt động giáo viên này vì đang phụ trách lớp học '
          'ở trạng thái Planned, Open hoặc Ongoing.',
        );
      }
    }

    if (intId != null) {
      await db.update(
        'teachers',
        {'status': status.value},
        where: 'id = ?',
        whereArgs: [intId],
      );
    } else {
      await db.update(
        'teachers',
        {'status': status.value},
        where: 'teacher_code = ?',
        whereArgs: [teacherId.trim().toUpperCase()],
      );
    }

    try {
      await _firestoreTeachersCol.doc(teacherId).set({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    _notifyChanges();
  }
}

/// Provider cung cấp TeacherRepository kết nối cả SQLite và Firestore
final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepositoryImpl(
    ref.watch(databaseHelperProvider),
    ref.watch(firestoreProvider),
  );
});
