import 'package:cloud_firestore/cloud_firestore.dart';

/// Trạng thái của giáo viên trong hệ thống LCMS
enum TeacherStatus {
  active('active', 'Đang hoạt động'),
  inactive('inactive', 'Ngưng hoạt động');

  const TeacherStatus(this.value, this.label);

  final String value;
  final String label;

  static TeacherStatus fromString(String? val) {
    if (val?.toLowerCase() == 'inactive') {
      return TeacherStatus.inactive;
    }
    return TeacherStatus.active;
  }
}

/// Model đại diện cho một Giáo viên (Collection: `teachers`)
class Teacher {
  final String id;
  final String code;
  final String fullName;
  final List<String> specialties;
  final String email;
  final String phoneNumber;
  final TeacherStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? accountUid;

  const Teacher({
    required this.id,
    required this.code,
    required this.fullName,
    required this.specialties,
    required this.email,
    required this.phoneNumber,
    this.status = TeacherStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.accountUid,
  });

  /// Kiểm tra giáo viên có đang ở trạng thái hoạt động không
  bool get isActive => status == TeacherStatus.active;

  /// Chuỗi hiển thị chuyên môn cách nhau bằng dấu phẩy
  String get specialtiesFormatted =>
      specialties.isEmpty ? 'Chưa cập nhật' : specialties.join(', ');

  /// Parse dữ liệu từ Firestore DocumentSnapshot
  factory Teacher.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Teacher.fromMap(data, doc.id);
  }

  /// Parse dữ liệu từ Map và document ID
  factory Teacher.fromMap(Map<String, dynamic> map, String id) {
    return Teacher(
      id: id,
      code: (map['code'] as String?)?.trim() ?? '',
      fullName: (map['fullName'] as String?)?.trim() ?? '',
      specialties: (map['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      email: (map['email'] as String?)?.trim() ?? '',
      phoneNumber: (map['phoneNumber'] as String?)?.trim() ?? '',
      status: TeacherStatus.fromString(map['status'] as String?),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      accountUid: map['accountUid'] as String?,
    );
  }

  /// Chuyển đối tượng Teacher sang Map để lưu trữ trên Firestore
  Map<String, dynamic> toMap() {
    return {
      'code': code.trim().toUpperCase(),
      'fullName': fullName.trim(),
      'specialties': specialties,
      'email': email.trim(),
      'phoneNumber': phoneNumber.trim(),
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (accountUid != null) 'accountUid': accountUid,
    };
  }

  /// Tạo bản sao với các thuộc tính được cập nhật
  Teacher copyWith({
    String? id,
    String? code,
    String? fullName,
    List<String>? specialties,
    String? email,
    String? phoneNumber,
    TeacherStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? accountUid,
  }) {
    return Teacher(
      id: id ?? this.id,
      code: code ?? this.code,
      fullName: fullName ?? this.fullName,
      specialties: specialties ?? this.specialties,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountUid: accountUid ?? this.accountUid,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Teacher &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code;

  @override
  int get hashCode => id.hashCode ^ code.hashCode;
}

