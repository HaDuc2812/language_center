import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../models/teacher_model.dart';
import 'teacher_repository.dart';

/// Triển khai TeacherRepository kết nối Cloud Firestore và áp dụng chặt chẽ các ràng buộc nghiệp vụ
class TeacherRepositoryImpl implements TeacherRepository {
  final FirebaseFirestore _firestore;

  TeacherRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _teachersCol =>
      _firestore.collection('teachers');

  CollectionReference<Map<String, dynamic>> get _classesCol =>
      _firestore.collection('classes');

  @override
  Stream<List<Teacher>> getTeachersStream() {
    return _teachersCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Teacher.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<List<Teacher>> getTeachers() async {
    final snapshot =
        await _teachersCol.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => Teacher.fromFirestore(doc)).toList();
  }

  @override
  Future<Teacher?> getTeacherById(String id) async {
    final doc = await _teachersCol.doc(id).get();
    if (!doc.exists) return null;
    return Teacher.fromFirestore(doc);
  }

  @override
  Future<void> createTeacher(Teacher teacher) async {
    final normalizedCode = teacher.code.trim().toUpperCase();

    // RÀNG BUỘC 1: Kiểm tra mã giáo viên đã tồn tại chưa
    final duplicateQuery = await _teachersCol
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (duplicateQuery.docs.isNotEmpty) {
      throw TeacherBusinessException(
        'Mã giáo viên "$normalizedCode" đã tồn tại trong hệ thống. Vui lòng chọn mã khác.',
      );
    }

    // Tạo document mới với ServerTimestamp
    final docRef = _teachersCol.doc();
    final data = <String, dynamic>{
      'code': normalizedCode,
      'fullName': teacher.fullName.trim(),
      'specialties': teacher.specialties,
      'email': teacher.email.trim(),
      'phoneNumber': teacher.phoneNumber.trim(),
      'status': teacher.status.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (teacher.accountUid != null) 'accountUid': teacher.accountUid,
    };

    await docRef.set(data);
  }

  @override
  Future<void> updateTeacher(Teacher teacher) async {
    final docRef = _teachersCol.doc(teacher.id);
    final existingDoc = await docRef.get();

    if (!existingDoc.exists) {
      throw const TeacherBusinessException(
        'Không tìm thấy thông tin giáo viên để cập nhật.',
      );
    }

    // RÀNG BUỘC 2: Không cho phép sửa trường 'code' và 'createdAt' khi Update
    final data = <String, dynamic>{
      'fullName': teacher.fullName.trim(),
      'specialties': teacher.specialties,
      'email': teacher.email.trim(),
      'phoneNumber': teacher.phoneNumber.trim(),
      'status': teacher.status.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'accountUid': teacher.accountUid,
    };

    await docRef.update(data);
  }

  @override
  Future<void> deleteTeacher(String teacherId) async {
    // RÀNG BUỘC 3: Trước khi xóa, kiểm tra collection `classes` xem có lớp nào gắn teacherId này không
    final assignedClassesQuery = await _classesCol
        .where('teacherId', isEqualTo: teacherId)
        .limit(1)
        .get();

    if (assignedClassesQuery.docs.isNotEmpty) {
      throw const TeacherBusinessException(
        'Không thể xóa giáo viên này vì đã được phân công lớp học trong hệ thống. '
        'Vui lòng chuyển trạng thái sang "Ngưng hoạt động" (inactive) thay vì xóa.',
      );
    }

    await _teachersCol.doc(teacherId).delete();
  }

  @override
  Future<void> updateTeacherStatus(String teacherId, TeacherStatus status) async {
    // RÀNG BUỘC 4: Khi chuyển sang inactive, kiểm tra lớp đang phụ trách có trạng thái Planned, Open, hoặc Ongoing
    if (status == TeacherStatus.inactive) {
      final activeClassesQuery = await _classesCol
          .where('teacherId', isEqualTo: teacherId)
          .where('status', whereIn: ['Planned', 'Open', 'Ongoing'])
          .limit(1)
          .get();

      if (activeClassesQuery.docs.isNotEmpty) {
        throw const TeacherBusinessException(
          'Không thể ngưng hoạt động giáo viên này vì đang phụ trách lớp học '
          'ở trạng thái Planned, Open hoặc Ongoing.',
        );
      }
    }

    await _teachersCol.doc(teacherId).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Provider cung cấp TeacherRepository qua Riverpod
final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepositoryImpl(ref.watch(firestoreProvider));
});

