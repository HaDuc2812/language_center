/// Hồ sơ khóa học - tương ứng bảng `course` trong SQLite
class CourseRecord {
  const CourseRecord({
    required this.id,
    required this.courseCode,
    required this.name,
    required this.description,
    required this.language,
    required this.level,
    required this.plannedLessons,
    required this.durationWeeks,
    required this.status,
  });

  final int id;
  final String courseCode;
  final String name;
  final String description;
  final String language;
  final String level;
  final int plannedLessons;
  final int durationWeeks;
  final String status; // 'active' | 'inactive'
}

/// Hồ sơ phòng học - tương ứng bảng `classrooms` trong SQLite
class ClassroomRecord {
  const ClassroomRecord({
    required this.id,
    required this.roomCode,
    required this.roomName,
    required this.capacity,
    required this.status,
  });

  final int id;
  final String roomCode;
  final String roomName;
  final int capacity;
  final String status; // 'active' | 'inactive'
}
