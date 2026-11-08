import '../models/teacher_model.dart';

/// Exception đại diện cho lỗi vi phạm nghiệp vụ giáo viên trong LCMS
class TeacherBusinessException implements Exception {
  final String message;

  const TeacherBusinessException(this.message);

  @override
  String toString() => message;
}

/// Interface trừu tượng cho Repository quản lý Giáo viên
abstract class TeacherRepository {
  /// Lắng nghe luồng dữ liệu danh sách giáo viên realtime từ Firestore
  Stream<List<Teacher>> getTeachersStream();

  /// Lấy toàn bộ danh sách giáo viên một lần
  Future<List<Teacher>> getTeachers();

  /// Lấy thông tin chi tiết một giáo viên theo Document ID
  Future<Teacher?> getTeacherById(String id);

  /// Thêm mới một giáo viên (Ràng buộc: code không được trùng)
  Future<void> createTeacher(Teacher teacher);

  /// Cập nhật thông tin giáo viên (Ràng buộc: không thay đổi code)
  Future<void> updateTeacher(Teacher teacher);

  /// Xóa giáo viên (Ràng buộc: không có bất kỳ lớp học nào tham chiếu)
  Future<void> deleteTeacher(String teacherId);

  /// Cập nhật trạng thái giáo viên (Ràng buộc khi ngưng hoạt động: không có lớp Planned/Open/Ongoing)
  Future<void> updateTeacherStatus(String teacherId, TeacherStatus status);
}

