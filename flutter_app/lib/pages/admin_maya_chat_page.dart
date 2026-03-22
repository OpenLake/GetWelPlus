import 'package:flutter/material.dart';
import 'package:flutter_app/core/error_messages.dart';
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

  List<Map<String, String>> _patients = []; // {id, name}
  String? _selectedPatientId;
  String? _selectedPatientName;

  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(isAdminMode: true);
    _messages.add({
      "text": "Hi Doctor 👋 I’m Maya, your assistant. Pick a patient to give me context, or ask me anything.",
      "isUser": false,
    });
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isFetchingPatients = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('patient_profiles')
          .select('user_id, full_name')
          .order('full_name', ascending: true);

      final data = (response as List).cast<Map<String, dynamic>>();

      setState(() {
        _patients = data
            .where((row) => row['user_id'] != null)
            .map((row) => {
                  'id': row['user_id'] as String,
                  'name': (row['full_name'] as String?) ?? 'Unknown',
                })
            .toList();
        _isFetchingPatients = false;
      });
    } catch (e) {
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

  Future<void> _setPatientContext(String? patientId, String? patientName) async {
    setState(() {
      _selectedPatientId = patientId;
      _selectedPatientName = patientName;
      _isLoading = true;
    });

    _chatService = ChatService(
      isAdminMode: true,
      targetPatientId: patientId,
      usePersonalData: true,
    );

    // reset conversation
    setState(() {
      _messages.clear();
      _messages.add({
        "text": patientId != null
            ? "Now assisting with $patientName's case. Ask me anything."
            : "Now assisting without a specific patient. Ask me anything.",
        "isUser": false,
      });
      _isLoading = false;
    });
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
      final response = await _chatService.sendMessage(text);
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
            "text": "I’m having trouble reaching Maya right now. Try again shortly.",
            "isUser": false,
          });
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e, fallback: 'Something went wrong. Please try again.')),
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
                _selectedPatientName != null && _selectedPatientName!.isNotEmpty
                    ? 'Maya (Doctor Assistant) — $_selectedPatientName'
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              child: Text(patient['name'] ?? ''),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          final name = _patients.firstWhere(
                            (p) => p['id'] == value,
                            orElse: () => {'name': 'Unknown'},
                          )['name'];
                          _setPatientContext(value, name);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
