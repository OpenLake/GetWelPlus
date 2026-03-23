import 'package:flutter/material.dart';
import 'package:flutter_app/models/meeting_model.dart';
import 'package:flutter_app/widgets/meeting_card.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/pages/doctor_chat_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  List<Meeting> _allMeetings = [];
  bool _isLoading = true;

  final _supabase = Supabase.instance.client;

  List<Meeting> get _attended => _allMeetings
      .where((m) => m.isAttended && m.status != 'cancelled')
      .toList();

  List<Meeting> get _scheduled => _allMeetings
      .where((m) => !m.isAttended && m.status != 'cancelled')
      .toList();

  List<Meeting> get _cancelled => _allMeetings
      .where((m) => m.status == 'cancelled')
      .toList();

  DateTime? _selectedDateTime;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  Future<void> _fetchMeetings() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('meetings')
          .select('*, patient_profiles(display_id, full_name)')
          .eq('patient_id', userId)
          .eq('meeting_type', 'chat')
          .order('scheduled_at', ascending: true);

      setState(() {
        _allMeetings = (response as List)
            .map((json) => Meeting.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching chats: $e')),
        );
      }
    }
  }

  Future<void> _scheduleChat() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _selectedDateTime == null) return;

    try {
      await _supabase.from('meetings').insert({
        'patient_id': userId,
        'title': _titleController.text.trim().isEmpty
            ? 'Chat Session'
            : _titleController.text.trim(),
        'notes': _notesController.text.trim(),
        'scheduled_at': _selectedDateTime!.toUtc().toIso8601String(),
        'status': 'pending',
        'meeting_type': 'chat',
      });

      await _fetchMeetings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling chat: $e')),
        );
      }
    }
  }

  Future<void> _cancelMeeting(Meeting meeting) async {
    try {
      await _supabase
          .from('meetings')
          .update({'status': 'cancelled'})
          .eq('id', meeting.id);

      await _fetchMeetings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling chat: $e')),
        );
      }
    }
  }

  void _showScheduleSheet() {
    _selectedDateTime = null;
    _notesController.clear();
    _titleController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Schedule a Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date & Time picker
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );

                          if (date == null || !mounted) return;

                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );

                          if (time == null || !mounted) return;

                          setSheetState(() {
                            _selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedDateTime != null
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey.shade700,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  color: Color(0xFF4CAF50), size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDateTime != null
                                    ? DateFormat('MMM d, yyyy · h:mm a')
                                        .format(_selectedDateTime!)
                                    : 'Select Date & Time',
                                style: TextStyle(
                                  color: _selectedDateTime != null
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title field
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _titleController.text.isNotEmpty
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey.shade700,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF4CAF50)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes field
                      TextField(
                        controller: _notesController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Notes / Reason (optional)',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF4CAF50)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _selectedDateTime == null
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  await _scheduleChat();
                                },
                          child: const Text(
                            'Schedule Chat',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _titleController.addListener(() => setState(() {}));
    _fetchMeetings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('1:1 Chat'),
          centerTitle: true,
          elevation: 4,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF4CAF50),
            indicatorWeight: 3,
            labelColor: const Color(0xFF4CAF50),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Scheduled'),
              Tab(text: 'Attended'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4CAF50),
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  // Scheduled tab
                  _scheduled.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 52, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No upcoming chats',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _scheduled.length,
                          itemBuilder: (context, index) {
                            final meeting = _scheduled[index];
                            return MeetingCard(
                              meeting: meeting,
                              onTap: () {},
                              onCancel: () => _cancelMeeting(meeting),
                              onJoin: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DoctorChatPage(
                                      meetingId: meeting.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                  // Attended tab
                  _attended.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 52, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No past chats yet',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _attended.length,
                          itemBuilder: (context, index) => MeetingCard(
                            meeting: _attended[index],
                            onTap: () {},
                            onCancel: null,
                            onJoin: null,
                          ),
                        ),

                  // Cancelled tab
                  _cancelled.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cancel_outlined,
                                  size: 52, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No cancelled chats',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cancelled.length,
                          itemBuilder: (context, index) => MeetingCard(
                            meeting: _cancelled[index],
                            onTap: () {},
                            onCancel: null,
                            onJoin: null,
                          ),
                        ),
                ],
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.black,
          onPressed: _showScheduleSheet,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}