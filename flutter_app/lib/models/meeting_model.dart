class Meeting {
  final String title;
  final DateTime scheduledAt;
  final String notes;

  const Meeting({
    required this.title,
    required this.scheduledAt,
    required this.notes,
  });

  // if scheduled time has passed → it's attended
  bool get isAttended => scheduledAt.isBefore(DateTime.now());
}