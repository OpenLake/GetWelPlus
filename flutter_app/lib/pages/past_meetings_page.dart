import 'package:flutter/material.dart';
import 'package:flutter_app/models/meeting_model.dart';
import 'package:flutter_app/widgets/meeting_card.dart';

class PastMeetingsPage extends StatefulWidget {
  const PastMeetingsPage({super.key});

  @override
  State<PastMeetingsPage> createState() => _PastMeetingsPageState();
}

class _PastMeetingsPageState extends State<PastMeetingsPage> {
  final List<Meeting> _pastMeetings = [
    Meeting(
      title: 'Initial Consultation',
      patientName: 'Rahul Sharma',
      scheduledAt: DateTime.now().subtract(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      notes: 'First session, discussed anxiety triggers',
      status: 'completed',
    ),
    Meeting(
      title: 'Therapy Session',
      patientName: 'Priya Mehta',
      scheduledAt: DateTime.now().subtract(const Duration(days: 10)),
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      notes: 'CBT techniques introduced',
      status: 'completed',
    ),
    Meeting(
      title: 'Stress Assessment',
      patientName: 'Arjun Nair',
      scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      notes: 'PSS scale administered',
      status: 'completed',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Meetings'),
        centerTitle: true,
        elevation: 4,
      ),
      body: _pastMeetings.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_outlined, size: 52, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No past meetings yet',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pastMeetings.length,
              itemBuilder: (context, index) => MeetingCard(
                meeting: _pastMeetings[index],
                onTap: () {},
              ),
            ),
    );
  }
}