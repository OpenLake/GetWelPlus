class Meeting {
  final String id;
  final String patientId;
  final String title;
  final String patientDisplayId; // doctor-facing unique ID (not full patient full name)
  final DateTime scheduledAt;
  final DateTime createdAt;
  final String notes;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String meetingType; // 'video' or 'chat'
  final List<String> tags;

  const Meeting({
    this.id = '',
    this.patientId = '',
    required this.title,
    this.patientDisplayId = '',
    required this.scheduledAt,
    required this.createdAt,
    required this.notes,
    required this.status,
    this.meetingType = 'video',
    this.tags = const [],
  });

  // Parses a Supabase row into a Meeting object
  factory Meeting.fromJson(Map<String, dynamic> json) {
    final patientProfile = extractPatientProfile(json['patient_profiles']);

    return Meeting(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      title: json['title'] ?? '',
      patientDisplayId: (patientProfile?['display_id'] ?? '').toString(),
      scheduledAt: DateTime.parse(json['scheduled_at']).toLocal(),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'pending',
      meetingType: json['meeting_type'] ?? 'video',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  bool get isAttended =>
      scheduledAt.add(const Duration(hours: 24)).isBefore(DateTime.now());

  bool get isChat => meetingType == 'chat';

  String get displayStatus {
    if (isAttended && status == 'confirmed') return 'completed';
    return status;
  }

  String get jitsiRoom =>
      'getwelplus-${id.isEmpty ? title.replaceAll(' ', '-').toLowerCase() : id}';

  static Map<String, dynamic>? extractPatientProfile(dynamic rawProfile) {
    if (rawProfile is Map<String, dynamic>) {
      return rawProfile;
    }
    if (rawProfile is List && rawProfile.isNotEmpty) {
      final first = rawProfile.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
    }
    return null;
  }
}
