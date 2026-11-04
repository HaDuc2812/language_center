class StudentRecord {
  const StudentRecord({
    required this.id,
    required this.code,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.status,
  });

  final int id;
  final String code;
  final String fullName;
  final String email;
  final String phone;
  final String status;
}

class ClassRecord {
  const ClassRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.courseName,
    required this.teacherName,
    required this.roomName,
    required this.status,
    required this.enrolledCount,
    required this.capacity,
    required this.startDate,
    required this.endDate,
    required this.scheduleDetails,
  });

  final int id;
  final String code;
  final String name;
  final String courseName;
  final String teacherName;
  final String roomName;
  final String status;
  final int enrolledCount;
  final int capacity;
  final DateTime startDate;
  final DateTime endDate;
  final String scheduleDetails;
}

class EnrollmentRecord {
  const EnrollmentRecord({
    required this.id,
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    required this.classId,
    required this.classCode,
    required this.className,
    required this.status,
    required this.enrolledAt,
    this.cancelledAt,
    this.cancelReason,
    this.score,
    this.resultComment,
  });

  final int id;
  final int studentId;
  final String studentCode;
  final String studentName;
  final int classId;
  final String classCode;
  final String className;
  final String status;
  final DateTime enrolledAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final double? score;
  final String? resultComment;
}

class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.classId,
    required this.number,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.status,
  });

  final int id;
  final int classId;
  final int number;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.enrollmentId,
    required this.studentCode,
    required this.studentName,
    this.attendanceId,
    this.status,
    this.note = '',
  });

  final int enrollmentId;
  final String studentCode;
  final String studentName;
  final int? attendanceId;
  final String? status;
  final String note;
}

class StudentHistoryRecord {
  const StudentHistoryRecord({
    required this.enrollment,
    required this.attendances,
  });

  final EnrollmentRecord enrollment;
  final List<({String sessionTitle, String status, String note})> attendances;
}
