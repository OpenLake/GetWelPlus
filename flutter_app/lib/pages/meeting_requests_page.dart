import 'package:flutter/material.dart';
import 'package:flutter_app/models/meeting_model.dart';
import 'package:flutter_app/widgets/meeting_request_card.dart';
import 'package:intl/intl.dart';

class MeetingRequestsPage extends StatefulWidget {
  const MeetingRequestsPage({super.key});

  @override
  State<MeetingRequestsPage> createState() => _MeetingRequestsPageState();
}

class _MeetingRequestsPageState extends State<MeetingRequestsPage> {
  List<Meeting> _requests = [
    Meeting(
      title: 'Anxiety Consultation',
      patientName: 'Rahul Sharma',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      notes: 'Feeling anxious for the past few weeks',
      status: 'pending',
    ),
    Meeting(
      title: 'Follow-up Session',
      patientName: 'Priya Mehta',
      scheduledAt: DateTime.now().add(const Duration(days: 4)),
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      notes: 'Follow up on previous therapy session',
      status: 'pending',
    ),
    Meeting(
      title: 'Stress Management',
      patientName: 'Arjun Nair',
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      notes: 'Work related stress issues',
      status: 'pending',
    ),
  ];

  void _acceptRequest(int index) {
    setState(() {
      _requests.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting request accepted!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _rejectRequest(int index) {
    setState(() {
      _requests.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting request rejected!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Requests'),
        centerTitle: true,
        elevation: 4,
      ),
      body: _requests.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 52, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No pending requests',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, index) => MeetingRequestCard(
                meeting: _requests[index],
                onAccept: () => _acceptRequest(index),
                onReject: () => _rejectRequest(index),
              ),
            ),
    );
  }
}