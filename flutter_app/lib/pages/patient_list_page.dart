import 'package:flutter/material.dart';
import 'package:flutter_app/models/patient_model.dart';
import 'package:flutter_app/widgets/patient_card.dart';
import 'package:flutter_app/pages/patient_detail_page.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  final List<Patient> _patients = [
    Patient(
      name: 'Rahul Sharma',
      email: 'rahul@email.com',
      phone: '+91 98765 43210',
      age: 28,
      lastSessionDate: DateTime.now().subtract(const Duration(days: 5)),
      pastIssues: ['Anxiety', 'Stress', 'Sleep disorder'],
      pastInteractions: [
        'Jan 10 — Discussed anxiety triggers and coping mechanisms',
        'Feb 3 — CBT session, patient showing improvement',
        'Mar 1 — Follow-up, sleep patterns improving',
      ],
    ),
    Patient(
      name: 'Priya Mehta',
      email: 'priya@email.com',
      phone: '+91 91234 56789',
      age: 34,
      lastSessionDate: DateTime.now().subtract(const Duration(days: 10)),
      pastIssues: ['Depression', 'Social anxiety'],
      pastInteractions: [
        'Jan 20 — Initial consultation, mild depression diagnosed',
        'Feb 15 — Started CBT, patient cooperative',
      ],
    ),
    Patient(
      name: 'Arjun Nair',
      email: 'arjun@email.com',
      phone: '+91 99887 76655',
      age: 45,
      lastSessionDate: DateTime.now().subtract(const Duration(days: 3)),
      pastIssues: ['Work stress', 'Burnout'],
      pastInteractions: [
        'Feb 20 — PSS scale administered, high stress levels',
        'Mar 4 — Stress management techniques discussed',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient List'),
        centerTitle: true,
        elevation: 4,
      ),
      body: _patients.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 52, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No patients yet',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _patients.length,
              itemBuilder: (context, index) => PatientCard(
                patient: _patients[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PatientDetailPage(
                      patient: _patients[index],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}