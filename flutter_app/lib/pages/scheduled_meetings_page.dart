import 'package:flutter/material.dart';
import 'package:flutter_app/models/meeting_model.dart';
import 'package:flutter_app/widgets/meeting_card.dart';

class ScheduledMeetingsPage extends StatefulWidget {
  const ScheduledMeetingsPage({super.key});

  @override
  State<ScheduledMeetingsPage> createState() => _ScheduledMeetingsPageState();
}

class _ScheduledMeetingsPageState extends State<ScheduledMeetingsPage> {
  final List<Meeting> _scheduledMeetings = [
    Meeting(
      title: 'Anxiety Consultation',
      patientName: 'Rahul Sharma',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      notes: 'Feeling anxious for the past few weeks',
      status: 'confirmed',
    ),
    Meeting(
      title: 'Stress Management',
      patientName: 'Priya Mehta',
      scheduledAt: DateTime.now().add(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      notes: 'Work related stress issues',
      status: 'confirmed',
    ),
    Meeting(
      title: 'Depression Follow-up',
      patientName: 'Arjun Nair',
      scheduledAt: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      notes: 'Monthly follow-up session',
      status: 'confirmed',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Meetings'),
        centerTitle: true,
        elevation: 4,
      ),
      body: _scheduledMeetings.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy_outlined,
                      size: 52, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No scheduled meetings',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _scheduledMeetings.length,
              itemBuilder: (context, index) => MeetingCard(
                meeting: _scheduledMeetings[index],
                onTap: () {},
              ),
            ),
    );
  }
}