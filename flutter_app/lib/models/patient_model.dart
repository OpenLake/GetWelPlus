class Patient {
  final String name;
  final String email;
  final String phone;
  final int age;
  final DateTime lastSessionDate;
  final List<String> pastIssues;
  final List<String> pastInteractions;

  const Patient({
    required this.name,
    required this.email,
    required this.phone,
    required this.age,
    required this.lastSessionDate,
    required this.pastIssues,
    required this.pastInteractions,
  });
}