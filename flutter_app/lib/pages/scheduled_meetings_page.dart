import 'package:flutter/material.dart';
import 'package:flutter_app/core/error_messages.dart';
import 'package:flutter_app/models/meeting_model.dart';
import 'package:flutter_app/pages/doctor_chat_page.dart';
import 'package:flutter_app/services/doctor_data_service.dart';
import 'package:flutter_app/widgets/meeting_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduledMeetingsPage extends StatefulWidget {
  const ScheduledMeetingsPage({super.key});

  @override
  State<ScheduledMeetingsPage> createState() => _ScheduledMeetingsPageState();
}

class _ScheduledMeetingsPageState extends State<ScheduledMeetingsPage> {
  List<Meeting> _scheduledMeetings = [];
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;
  late final DoctorDataService _doctorDataService;

  @override
  void initState() {
    super.initState();
    _doctorDataService = DoctorDataService(client: _supabase);
    _fetchMeetings();
  }

  // Fetch all confirmed future meetings from Supabase
  Future<void> _fetchMeetings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('meetings')
          .select('*')
          .eq('status', 'confirmed')
          .gte(
            'scheduled_at',
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .toIso8601String(),
          )
          .order('scheduled_at', ascending: true);

      final typedRows = (response as List).cast<Map<String, dynamic>>();
      final profilesById = await _doctorDataService.fetchPatientProfilesByIds(
        typedRows.map((row) => (row['patient_id'] ?? '').toString()),
      );

      setState(() {
        _scheduledMeetings = _doctorDataService.mapMeetings(
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
              'Error fetching meetings: ${friendlyErrorMessage(e)}',
            ),
          ),
        );
      }
    }
  }

  // Cancel a meeting in Supabase
  Future<void> _cancelMeeting(Meeting meeting) async {
    try {
      await _supabase
          .from('meetings')
          .update({'status': 'cancelled'})
          .eq('id', meeting.id);

      await _fetchMeetings(); // refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error cancelling meeting: ${friendlyErrorMessage(e)}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scheduled Meetings'),
          centerTitle: true,
          elevation: 4,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              )
            : _scheduledMeetings.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 52,
                      color: Colors.grey,
                    ),
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
                itemBuilder: (context, index) {
                  final meeting = _scheduledMeetings[index];
                  return MeetingCard(
                    meeting: meeting,
                    onTap: () {},
                    onCancel: () => _cancelMeeting(meeting),
                    onJoin: () async {
                      if (meeting.isChat) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorChatPage(
                              meetingId: meeting.id,
                              isDoctor: true,
                            ),
                          ),
                        );
                      } else {
                        final url = Uri.parse(
                          'https://meet.jit.si/${meeting.jitsiRoom}',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open video call'),
                              ),
                            );
                          }
                        }
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
