class Meeting {
  final String id;
  final String title;
  final String patientName;
  final String patientDisplayId; // NEW — doctor sees this
  final DateTime scheduledAt;
  final DateTime createdAt;
  final String notes;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String meetingType; // 'video' or 'chat'

  const Meeting({
    this.id = '',
    required this.title,
    required this.patientName,
    this.patientDisplayId = '',
    required this.scheduledAt,
    required this.createdAt,
    required this.notes,
    required this.status,
    this.meetingType = 'video',
  });

  // Parses a Supabase row into a Meeting object
  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      patientName: json['patient_profiles']?['full_name'] ?? '',
      patientDisplayId: json['patient_profiles']?['display_id'] ?? '',
      scheduledAt: DateTime.parse(json['scheduled_at']),
      createdAt: DateTime.parse(json['created_at']),
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'pending',
      meetingType: json['meeting_type'] ?? 'video',
    );
  }

  bool get isAttended => scheduledAt
      .add(const Duration(hours: 2))
      .isBefore(DateTime.now());

  bool get isChat => meetingType == 'chat';

  String get displayStatus {
    if (isAttended && status == 'confirmed') return 'completed';
    return status;
  }

  String get jitsiRoom =>
      'getwelplus-${id.isEmpty ? title.replaceAll(' ', '-').toLowerCase() : id}';
}