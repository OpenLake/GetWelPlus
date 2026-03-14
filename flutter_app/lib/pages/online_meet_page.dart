import 'package:flutter/material.dart';
import 'package:flutter_app/models/meeting_model.dart';
import 'package:flutter_app/widgets/meeting_card.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/pages/doctor_chat_page.dart';
import 'package:url_launcher/url_launcher.dart';

class OnlineMeetPage extends StatefulWidget {
  const OnlineMeetPage({super.key});

  @override
  State<OnlineMeetPage> createState() => _OnlineMeetPageState();
}

class _OnlineMeetPageState extends State<OnlineMeetPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final List<Meeting> _allMeetings = [
    Meeting(
      title: 'Session with Dr. Mehta',
      patientName: 'John Doe',
      scheduledAt: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      notes: 'Follow-up on anxiety management',
      status: 'confirmed',
      meetingType: 'video',
    ),
    Meeting(
      title: 'Stress Check Session',
      patientName: 'John Doe',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      notes: 'Initial stress assessment',
      status: 'pending',
      meetingType: 'chat',
    ),
    Meeting(
      title: 'Group Therapy',
      patientName: 'John Doe',
      scheduledAt: DateTime.now().add(const Duration(minutes: 4)),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      notes: 'Weekly group session',
      status: 'confirmed',
      meetingType: 'chat',
    ),
  ];

  List<Meeting> get _attended => _allMeetings
      .where((m) => m.isAttended && m.status != 'cancelled')
      .toList();

  List<Meeting> get _scheduled => _allMeetings
      .where((m) => !m.isAttended || m.status == 'cancelled')
      .toList();

  DateTime? _selectedDateTime;
  String _selectedMeetingType = 'video'; // NEW
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  void _showScheduleSheet() {
    _selectedDateTime = null;
    _selectedMeetingType = 'video'; // reset to default
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
                        'Schedule a Meeting',
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
                  
                      // Meeting type dropdown — NEW
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4CAF50)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMeetingType,
                            dropdownColor: const Color(0xFF2A2A2A),
                            iconEnabledColor: const Color(0xFF4CAF50),
                            isExpanded: true,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            items: const [
                              DropdownMenuItem(
                                value: 'video',
                                child: Row(
                                  children: [
                                    Icon(Icons.videocam_outlined,
                                        color: Color(0xFF4CAF50), size: 20),
                                    SizedBox(width: 12),
                                    Text('Video Call'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'chat',
                                child: Row(
                                  children: [
                                    Icon(Icons.chat_outlined,
                                        color: Color(0xFF4CAF50), size: 20),
                                    SizedBox(width: 12),
                                    Text('Chat'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setSheetState(() {
                                _selectedMeetingType = value;
                              });
                            },
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
                              : () {
                                  setState(() {
                                    _allMeetings.add(
                                      Meeting(
                                        title: _titleController.text
                                                .trim()
                                                .isEmpty
                                            ? 'My Session'
                                            : _titleController.text.trim(),
                                        patientName: 'Me',
                                        scheduledAt: _selectedDateTime!,
                                        createdAt: DateTime.now(),
                                        notes: _notesController.text.trim(),
                                        status: 'pending',
                                        meetingType: _selectedMeetingType, // NEW
                                      ),
                                    );
                                  });
                                  Navigator.pop(context);
                                },
                          child: const Text(
                            'Schedule Meeting',
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
    _tabController = TabController(length: 2, vsync: this);
    _titleController.addListener(() {
      setState(() {});
    });
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
          title: const Text('Online Meet'),
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
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Scheduled tab
            _scheduled.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_outlined,
                            size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No upcoming meetings',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 15),
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
                        onCancel: () {
                          setState(() {
                            final actual = _allMeetings.indexOf(meeting);
                            _allMeetings[actual] = Meeting(
                              title: meeting.title,
                              patientName: meeting.patientName,
                              scheduledAt: meeting.scheduledAt,
                              createdAt: meeting.createdAt,
                              notes: meeting.notes,
                              status: 'cancelled',
                              meetingType: meeting.meetingType, // preserved
                            );
                          });
                        },
                        onJoin: () async {
                          if (meeting.isChat) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DoctorChatPage(),
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

            // Attended tab
            _attended.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_outlined,
                            size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No past meetings yet',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 15),
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