import 'package:flutter/material.dart';
import 'package:flutter_app/core/error_messages.dart';
import 'package:flutter_app/models/meeting_model.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PastInteractionsPage extends StatefulWidget {
  final String patientId;
  final String patientDisplayId;

  const PastInteractionsPage({
    super.key,
    required this.patientId,
    required this.patientDisplayId,
  });

  @override
  State<PastInteractionsPage> createState() => _PastInteractionsPageState();
}

class _PastInteractionsPageState extends State<PastInteractionsPage> {
  List<Meeting> _meetings = [];
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchInteractions();
  }

  Future<void> _fetchInteractions() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('meetings')
          .select('*, patient_profiles(display_id, full_name)')
          .eq('patient_id', widget.patientId)
          .eq('status', 'confirmed')
          .lt('scheduled_at', DateTime.now().toIso8601String())
          .order('scheduled_at', ascending: false);

      setState(() {
        _meetings = (response as List)
            .map((json) => Meeting.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching interactions: ${friendlyErrorMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientDisplayId} — History'),
        centerTitle: true,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : _meetings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_outlined,
                          size: 52, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No past interactions yet',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = _meetings[index];
                    return _InteractionCard(meeting: meeting);
                  },
                ),
    );
  }
}

class _InteractionCard extends StatelessWidget {
  final Meeting meeting;

  const _InteractionCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    meeting.isChat
                        ? Icons.chat_outlined
                        : Icons.videocam_outlined,
                    color: const Color(0xFF4CAF50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy · h:mm a')
                            .format(meeting.scheduledAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFF4CAF50)),
                      ),
                    ],
                  ),
                ),

                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    meeting.isChat ? 'Chat' : 'Video',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ],
            ),

            // Notes
            if (meeting.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                meeting.notes,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Tags — only show if tags exist
            if (meeting.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: meeting.tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF4CAF50).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
