import 'package:flutter/material.dart';
import 'package:flutter_app/core/error_messages.dart';
import 'package:flutter_app/services/doctor_data_service.dart';
import 'package:flutter_app/services/chat_service.dart';
import 'package:flutter_app/widgets/chat_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminMayaChatPage extends StatefulWidget {
  const AdminMayaChatPage({super.key});

  @override
  State<AdminMayaChatPage> createState() => _AdminMayaChatPageState();
}

class _AdminMayaChatPageState extends State<AdminMayaChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  late ChatService _chatService;
  bool _isLoading = false;
  bool _isFetchingPatients = true;

  List<Map<String, dynamic>> _patients = []; // {id, displayId, context}
  String? _selectedPatientId;
  String? _selectedPatientDisplayId;
  String _selectedPatientContext = '';

  final List<Map<String, dynamic>> _messages = [];
  late final DoctorDataService _doctorDataService;

  @override
  void initState() {
    super.initState();
    _doctorDataService = DoctorDataService(client: Supabase.instance.client);
    _chatService = ChatService(isAdminMode: true);
    _messages.add({
      "text":
          "Hi Doctor 👋 I’m Maya, your assistant. Pick a patient to give me context, or ask me anything.",
      "isUser": false,
    });
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isFetchingPatients = true;
    });

    try {
      final meetings = await Supabase.instance.client
          .from('meetings')
          .select('patient_id, scheduled_at, status')
          .inFilter('status', ['pending', 'confirmed', 'completed']);

      final typedMeetings = (meetings as List).cast<Map<String, dynamic>>();
      final meetingCount = typedMeetings.length;
      debugPrint('[AdminMaya] meetings fetched: $meetingCount');

      final profilesById = await _doctorDataService.fetchPatientProfilesByIds(
        typedMeetings.map((row) => (row['patient_id'] ?? '').toString()),
      );
      debugPrint('[AdminMaya] profilesById keys=${profilesById.keys.toList()}');

      final patientMap = <String, Map<String, dynamic>>{};
      for (final row in typedMeetings) {
        final patientId = (row['patient_id'] as String?)?.trim();
        if (patientId == null || patientId.isEmpty) continue;

        final profile = profilesById[patientId];
        final displayId = (profile?['display_id'] as String?)?.trim() ?? '';
        final context = profile != null ? _buildPatientContext(profile) : '';
        debugPrint(
          '[AdminMaya] patientId=$patientId displayId=$displayId hasProfile=${profile != null} contextLength=${context.length}',
        );

        final existing = patientMap[patientId];
        if (existing != null && (existing['context'] as String).isNotEmpty) {
          continue;
        }

        patientMap[patientId] = {
          'id': patientId,
          'displayId': displayId.isNotEmpty ? displayId : patientId,
          'context': context,
        };
      }

      debugPrint('[AdminMaya] patient profiles resolved: ${patientMap.length}');

      setState(() {
        _patients = patientMap.values.toList()
          ..sort(
            (a, b) => (a['displayId'] ?? '').toLowerCase().compareTo(
              (b['displayId'] ?? '').toLowerCase(),
            ),
          );
        _isFetchingPatients = false;
      });
    } catch (e, stackTrace) {
      debugPrint('[AdminMaya] failed to load patients: $e');
      debugPrint(stackTrace.toString());
      setState(() {
        _patients = [];
        _isFetchingPatients = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _setPatientContext(String? patientId, String? displayId) async {
    debugPrint(
      '[AdminMaya] _setPatientContext patientId=$patientId displayId=$displayId',
    );
    setState(() {
      _selectedPatientId = patientId;
      _selectedPatientDisplayId = displayId;
      _isLoading = true;
    });

    var contextText = '';
    if (patientId != null) {
      final profile = await _doctorDataService.fetchPatientProfileById(patientId);
      if (profile != null) {
        contextText = _buildPatientContext(profile);
        debugPrint(
          '[AdminMaya] direct profile fetch built context length=${contextText.length}',
        );
      }

      if (contextText.isEmpty) {
        for (final patient in _patients) {
          if (patient['id'] == patientId) {
            contextText = (patient['context'] ?? '').toString();
            debugPrint(
              '[AdminMaya] fallback cached context length=${contextText.length}',
            );
            break;
          }
        }
      }
    }
    debugPrint('[AdminMaya] final selected context="$contextText"');

    _chatService = ChatService(
      isAdminMode: true,
      targetPatientId: patientId,
      usePersonalData: true,
      doctorProvidedPatientContext: contextText,
    );

    // reset conversation
    setState(() {
      _selectedPatientContext = contextText;
      _messages.clear();
      _messages.add({
        "text": patientId != null
            ? "Now assisting with patient ${displayId ?? patientId}. ${contextText.isNotEmpty ? 'Patient context has been shared with Maya.' : 'No patient context was found.'}"
            : "Now assisting without a specific patient. Ask me anything.",
        "isUser": false,
      });
      _isLoading = false;
    });
  }

  String _buildPatientContext(Map<String, dynamic>? profile) {
    if (profile == null) return '';
    debugPrint(
      '[AdminMaya] _buildPatientContext keys=${profile.keys.toList()} values={display_id: ${profile['display_id']}, age: ${profile['age']}, medical_conditions: ${profile['medical_conditions']}, current_medications: ${profile['current_medications']}, mental_health_concerns: ${profile['mental_health_concerns']}, therapy_history: ${profile['therapy_history']}, allergies: ${profile['allergies']}}',
    );
    final parts = <String>[];
    final displayId = (profile['display_id'] ?? '').toString().trim();
    final age = profile['age'];
    final medical = (profile['medical_conditions'] ?? '').toString().trim();
    final meds = (profile['current_medications'] ?? '').toString().trim();
    final concerns = (profile['mental_health_concerns'] ?? '')
        .toString()
        .trim();
    final therapy = (profile['therapy_history'] ?? '').toString().trim();
    final allergies = (profile['allergies'] ?? '').toString().trim();

    if (displayId.isNotEmpty) parts.add('Patient ID: $displayId');
    if (age != null && age.toString().isNotEmpty && age != 0) {
      parts.add('Age: $age');
    }
    if (medical.isNotEmpty) parts.add('Medical conditions: $medical');
    if (meds.isNotEmpty) parts.add('Current medications: $meds');
    if (concerns.isNotEmpty) parts.add('Mental health concerns: $concerns');
    if (therapy.isNotEmpty) parts.add('Therapy history: $therapy');
    if (allergies.isNotEmpty) parts.add('Allergies: $allergies');

    final summary = parts.join('\n');
    debugPrint('[AdminMaya] built summary="$summary"');
    return summary;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({"text": text, "isUser": true});
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final messageForMaya = _selectedPatientContext.isNotEmpty
          ? 'PATIENT PROFILE CONTEXT (selected by doctor):\n$_selectedPatientContext\n\nDOCTOR QUESTION:\n$text'
          : text;
      debugPrint(
        '[AdminMaya] sending message selectedPatientId=$_selectedPatientId contextLength=${_selectedPatientContext.length} payload="$messageForMaya"',
      );
      final response = await _chatService.sendMessage(messageForMaya);
      if (mounted) {
        setState(() {
          _messages.add({"text": response, "isUser": false});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            "text":
                "I’m having trouble reaching Maya right now. Try again shortly.",
            "isUser": false,
          });
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyErrorMessage(
                e,
                fallback: 'Something went wrong. Please try again.',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green.shade100,
              child: const Text(
                'M',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedPatientDisplayId != null &&
                        _selectedPatientDisplayId!.isNotEmpty
                    ? 'Maya (Doctor Assistant) - $_selectedPatientDisplayId'
                    : 'Maya (Doctor Assistant)',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Start fresh',
            onPressed: () {
              setState(() {
                _chatService.clearHistory();
                _messages.clear();
                _messages.add({
                  "text": "Fresh start! 🌱 What's on your mind?",
                  "isUser": false,
                });
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Text(
                    'Patient context',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  if (_isFetchingPatients)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: _selectedPatientId,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select patient (optional)'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._patients.map((patient) {
                            return DropdownMenuItem<String?>(
                              value: patient['id'],
                              child: Text(patient['displayId'] ?? ''),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          final displayId = _patients.firstWhere(
                            (p) => p['id'] == value,
                            orElse: () => {'displayId': ''},
                          )['displayId'];
                          _setPatientContext(value, displayId);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_selectedPatientId != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPatientDisplayId?.isNotEmpty == true
                          ? 'Active patient: $_selectedPatientDisplayId'
                          : 'Active patient: $_selectedPatientId',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedPatientContext.isNotEmpty
                          ? _selectedPatientContext
                          : 'No patient context found for this patient.',
                      style: TextStyle(
                        color: _selectedPatientContext.isNotEmpty
                            ? Colors.black87
                            : Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.green.shade100,
                              child: const Text(
                                'M',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Maya is typing...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final msg = _messages[index];
                    return ChatBubble(
                      message: msg['text'],
                      isUser: msg['isUser'],
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.black),
                        controller: _messageController,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Ask Maya for help…',
                          hintStyle: const TextStyle(color: Colors.black54),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: Colors.green,
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
