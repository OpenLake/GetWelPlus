class Meeting {
  final String id;
  final String title;
  final String patientName;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final String notes;
  final String status; // 'pending', 'confirmed', 'rejected', 'completed'
  final String meetingType; // 'video' or 'chat'

  const Meeting({
    this.id = '',
    required this.title,
    required this.patientName,
    required this.scheduledAt,
    required this.createdAt,
    required this.notes,
    required this.status,
    this.meetingType = 'video',
  });

  bool get isAttended => scheduledAt
      .add(const Duration(hours: 2))
      .isBefore(DateTime.now());

  bool get isChat => meetingType == 'chat';

  String get displayStatus {
    if (isAttended && status == 'confirmed') return 'completed';
    return status;
  }

  // Unique Jitsi room name derived from meeting id
  String get jitsiRoom => 'getwelplus-${id.isEmpty ? title.replaceAll(' ', '-').toLowerCase() : id}';
}