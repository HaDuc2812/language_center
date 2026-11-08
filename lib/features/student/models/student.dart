class Student {
  const Student({
    required this.id,
    required this.code,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String code;
  final String fullName;
  final String email;
  final String phone;

  /// 'studying' | 'active' | 'dropped' | 'graduated' | 'inactive'
  final String status;

  final DateTime createdAt;

  static const List<String> validStatuses = [
    'studying',
    'active',
    'dropped',
    'graduated',
    'inactive',
  ];

  static const Map<String, String> statusLabel = {
    'studying': 'Đang học',
    'active': 'Hoạt động',
    'dropped': 'Đã nghỉ',
    'graduated': 'Đã tốt nghiệp',
    'inactive': 'Ngưng hoạt động',
  };

  String get statusDisplay => statusLabel[status] ?? status;

  bool get canEnroll => status == 'studying' || status == 'active';

  Student copyWith({
    int? id,
    String? code,
    String? fullName,
    String? email,
    String? phone,
    String? status,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      code: code ?? this.code,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
