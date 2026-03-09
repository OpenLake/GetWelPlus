class Meeting {
  final String title;
  final String patientName;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final String notes;
  final String status; // 'pending', 'confirmed', 'rejected', 'completed'

  const Meeting({
    required this.title,
    required this.patientName,
    required this.scheduledAt,
    required this.createdAt,
    required this.notes,
    required this.status,
  });

  bool get isAttended => scheduledAt.isBefore(DateTime.now());
}