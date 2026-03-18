class Patient {
  final String id;
  final String displayId;
  final String name;
  final String email;
  final String phone;
  final int age;
  final String gender;
  final DateTime lastSessionDate;

  const Patient({
    this.id = '',
    this.displayId = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.age,
    this.gender = '',
    required this.lastSessionDate,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['user_id'] ?? '',
      displayId: json['display_id'] ?? '',
      name: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      lastSessionDate: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
}