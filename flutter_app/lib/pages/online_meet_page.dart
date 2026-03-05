import 'package:flutter/material.dart';
import 'package:flutter_app/models/meeting_model.dart';
import 'package:flutter_app/widgets/meeting_card.dart';
import 'package:intl/intl.dart';

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
      scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
      notes: 'Follow-up on anxiety management',
    ),
    Meeting(
      title: 'Group Therapy',
      scheduledAt: DateTime.now().subtract(const Duration(days: 10)),
      notes: 'Weekly group session',
    ),
    Meeting(
      title: 'Session with Dr. Rao',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      notes: 'First consultation',
    ),
    Meeting(
      title: 'Stress Management Workshop',
      scheduledAt: DateTime.now().add(const Duration(days: 7)),
      notes: 'Bring journal',
    ),
  ];

  List<Meeting> get _scheduled => _allMeetings.where((m) => !m.isAttended).toList();
  List<Meeting> get _attended => _allMeetings.where((m) => m.isAttended).toList();

  DateTime? _selectedDateTime;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  void _showScheduleSheet() {
    _selectedDateTime=null;
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
                    bottom: MediaQuery.of(context).viewInsets.bottom+20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
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
                                    ? DateFormat('MMM d, yyyy · h:mm a').format(_selectedDateTime!)
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
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _titleController.text.isNotEmpty
                                  ? const Color(0xFF4CAF50)  // ← green when filled
                                  : Colors.grey.shade700,     // ← grey when empty
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                
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
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
              
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
                                        title: _titleController.text.trim().isEmpty 
                                            ? 'My Session'          // ← fallback if user leaves it empty
                                            : _titleController.text.trim(),
                                        scheduledAt: _selectedDateTime!,
                                        notes: _notesController.text.trim(),
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
        setState(() {}); // rebuilds when title text changes
      });
  }

  @override
  void dispose() {
    _tabController.dispose(); // always dispose to free memory
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
                        Icon(Icons.event_busy_outlined, size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No upcoming meetings',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _scheduled.length,
                    itemBuilder: (context, index) => MeetingCard(
                      meeting: _scheduled[index],
                      onTap: () {},
                    ),
                  ),
            // Attended tab
              _attended.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_outlined, size: 52, color: Colors.grey),
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
                      itemCount: _attended.length,
                      itemBuilder: (context, index) => MeetingCard(
                        meeting: _attended[index],
                        onTap: () {},
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