import 'package:flutter/material.dart';
import 'package:flutter_app/core/error_messages.dart';
import 'package:flutter_app/models/meeting_model.dart';
import 'package:flutter_app/services/doctor_data_service.dart';
import 'package:flutter_app/widgets/meeting_request_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MeetingRequestsPage extends StatefulWidget {
  const MeetingRequestsPage({super.key});

  @override
  State<MeetingRequestsPage> createState() => _MeetingRequestsPageState();
}

class _MeetingRequestsPageState extends State<MeetingRequestsPage> {
  List<Meeting> _requests = [];
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;
  late final DoctorDataService _doctorDataService;

  @override
  void initState() {
    super.initState();
    _doctorDataService = DoctorDataService(client: _supabase);
    _fetchRequests();
  }

  // Fetch all pending meetings from Supabase
  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('meetings')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final typedRows = (response as List).cast<Map<String, dynamic>>();
      final profilesById = await _doctorDataService.fetchPatientProfilesByIds(
        typedRows.map((row) => (row['patient_id'] ?? '').toString()),
      );

      setState(() {
        _requests = _doctorDataService.mapMeetings(
          typedRows,
          profilesById: profilesById,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error fetching requests: ${friendlyErrorMessage(e)}',
            ),
          ),
        );
      }
    }
  }

  // Accept → update status to confirmed
  Future<void> _acceptRequest(Meeting meeting) async {
    try {
      await _supabase
          .from('meetings')
          .update({'status': 'confirmed'})
          .eq('id', meeting.id);

      await _fetchRequests(); // refresh list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting request accepted!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error accepting request: ${friendlyErrorMessage(e)}',
            ),
          ),
        );
      }
    }
  }

  // Reject → update status to cancelled
  Future<void> _rejectRequest(Meeting meeting) async {
    try {
      await _supabase
          .from('meetings')
          .update({'status': 'cancelled'})
          .eq('id', meeting.id);

      await _fetchRequests(); // refresh list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting request rejected!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error rejecting request: ${friendlyErrorMessage(e)}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Requests'),
        centerTitle: true,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : _requests.isEmpty
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
                onAccept: () => _acceptRequest(_requests[index]),
                onReject: () => _rejectRequest(_requests[index]),
              ),
            ),
    );
  }
}
