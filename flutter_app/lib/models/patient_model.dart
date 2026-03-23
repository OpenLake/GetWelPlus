class Patient {
  final String id;
  final String displayId;
  final String email;
  final String phone;
  final int age;
  final String gender;
  final String medicalConditions;
  final String currentMedications;
  final String mentalHealthConcerns;
  final String therapyHistory;
  final String allergies;
  final DateTime lastSessionDate;

  const Patient({
    this.id = '',
    this.displayId = '',
    required this.email,
    required this.phone,
    required this.age,
    this.gender = '',
    this.medicalConditions = '',
    this.currentMedications = '',
    this.mentalHealthConcerns = '',
    this.therapyHistory = '',
    this.allergies = '',
    required this.lastSessionDate,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['user_id'] ?? '',
      displayId: json['display_id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      medicalConditions: json['medical_conditions'] ?? '',
      currentMedications: json['current_medications'] ?? '',
      mentalHealthConcerns: json['mental_health_concerns'] ?? '',
      therapyHistory: json['therapy_history'] ?? '',
      allergies: json['allergies'] ?? '',
      lastSessionDate: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  factory Patient.fromProfile(
    Map<String, dynamic> json, {
    required String userId,
    required DateTime lastSessionDate,
  }) {
    return Patient(
      id: userId,
      displayId: (json['display_id'] ?? userId).toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      age: json['age'] ?? 0,
      gender: (json['gender'] ?? '').toString(),
      medicalConditions: (json['medical_conditions'] ?? '').toString(),
      currentMedications: (json['current_medications'] ?? '').toString(),
      mentalHealthConcerns: (json['mental_health_concerns'] ?? '').toString(),
      therapyHistory: (json['therapy_history'] ?? '').toString(),
      allergies: (json['allergies'] ?? '').toString(),
      lastSessionDate: lastSessionDate,
    );
  }
}
