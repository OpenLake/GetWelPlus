import 'package:flutter/material.dart';
import 'package:flutter_app/core/error_messages.dart';
import 'package:flutter_app/models/meeting_model.dart';
import 'package:flutter_app/widgets/meeting_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PastMeetingsPage extends StatefulWidget {
  const PastMeetingsPage({super.key});

  @override
  State<PastMeetingsPage> createState() => _PastMeetingsPageState();
}

class _PastMeetingsPageState extends State<PastMeetingsPage> {
  List<Meeting> _pastMeetings = [];
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchPastMeetings();
  }

  // Fetch all past confirmed meetings (scheduled_at is in the past)
  Future<void> _fetchPastMeetings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('meetings')
          .select('*, patient_profiles(display_id, full_name)')
          .eq('status', 'confirmed')
          .lt('scheduled_at', DateTime.now().toIso8601String())
          .order('scheduled_at', ascending: false);

      setState(() {
        _pastMeetings = (response as List)
            .map((json) => Meeting.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching past meetings: ${friendlyErrorMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Meetings'),
        centerTitle: true,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : _pastMeetings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_outlined,
                          size: 52, color: Colors.grey),
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
                    onCancel: null,
                    onJoin: null,
                  ),
                ),
    );
  }
}