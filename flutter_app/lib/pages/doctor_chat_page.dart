import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/chat_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorChatPage extends StatefulWidget {
  final String meetingId;
  final bool isDoctor;

  const DoctorChatPage({
    super.key,
    required this.meetingId,
    this.isDoctor = false,
  });

  @override
  State<DoctorChatPage> createState() => _DoctorChatPageState();
}

class _DoctorChatPageState extends State<DoctorChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;

  List<Map<String, Object>> _messages = [];
  List<String> _tags = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  static const List<String> _presetTags = [
    'Stressed',
    'Depressed',
    'Anxious',
    'Improving',
    'Critical',
  ];

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _fetchTags();
    _subscribeToMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('meeting_id', widget.meetingId)
          .order('created_at', ascending: true);

      setState(() {
        _messages = (response as List)
            .map((m) => <String, Object>{
                  'text': m['content'] as String,
                  'isUser': m['sender_id'] == _currentUserId,
                })
            .toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  Future<void> _fetchTags() async {
    try {
      final response = await _supabase
          .from('meetings')
          .select('tags')
          .eq('id', widget.meetingId)
          .single();

      setState(() {
        _tags = List<String>.from(response['tags'] ?? []);
      });
    } catch (e) {
      // tags fetch failed silently — not critical
    }
  }

  Future<void> _saveTags() async {
    try {
      await _supabase
          .from('meetings')
          .update({'tags': _tags})
          .eq('id', widget.meetingId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving tag: $e')),
        );
      }
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || _tags.contains(trimmed)) return;
    setState(() => _tags.add(trimmed));
    _saveTags();
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    _saveTags();
  }

  void _showTagSheet() {
    _customTagController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return 
            Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    24,
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
                      'Tag this session',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select how the patient is feeling',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Current tags
                    if (_tags.isNotEmpty) ...[
                      Text(
                        'Applied tags',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  labelStyle: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                                  backgroundColor: const Color(0xFF4CAF50),
                                  deleteIconColor: Colors.black54,
                                  onDeleted: () {
                                    _removeTag(tag);
                                    setSheetState(() {});
                                  },
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade800),
                      const SizedBox(height: 16),
                    ],

                    // Preset tags
                    Text(
                      'Quick tags',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetTags.map((tag) {
                        final isApplied = _tags.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            if (isApplied) {
                              _removeTag(tag);
                            } else {
                              _addTag(tag);
                            }
                            setSheetState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isApplied
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isApplied
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey.shade700,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: isApplied
                                    ? Colors.black
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Custom tag input
                    Text(
                      'Custom tag',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customTagController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'e.g. Needs follow-up',
                              hintStyle:
                                  TextStyle(color: Colors.grey.shade500),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            _addTag(_customTagController.text);
                            _customTagController.clear();
                            setSheetState(() {});
                          },
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.black, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _subscribeToMessages() {
    _channel = _supabase
        .channel('messages:${widget.meetingId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'meeting_id',
            value: widget.meetingId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            final isUser = newMessage['sender_id'] == _currentUserId;
            if (!isUser) {
              setState(() {
                _messages.add(<String, Object>{
                  'text': newMessage['content'] as String,
                  'isUser': false,
                });
              });
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'text': text as Object, 'isUser': true as Object});
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      await _supabase.from('messages').insert({
        'meeting_id': widget.meetingId,
        'sender_id': _currentUserId,
        'content': text,
      });
    } catch (e) {
      setState(() => _messages.removeLast());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messageController.dispose();
    _customTagController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1:1 Chat'),
        centerTitle: true,
        elevation: 4,
        // AppBar actions removed — tag button moved to input bar
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : Column(
              children: [
                // Tags strip — shown when tags exist
                if (_tags.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    color: const Color(0xFF1A2A1A),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF4CAF50)
                                          .withOpacity(0.5)),
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
                  ),

                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet.\nSay hello! 👋',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey, fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return ChatBubble(
                              message: msg['text'] as String,
                              isUser: msg['isUser'] as bool,
                            );
                          },
                        ),
                ),

                // Input bar
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    border: Border(
                        top: BorderSide(color: Colors.grey.shade800)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Tag button — doctor only
                        if (widget.isDoctor) ...[
                          GestureDetector(
                            onTap: _showTagSheet,
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _tags.isNotEmpty
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey.shade700,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: _tags.isNotEmpty
                                        ? const Color(0xFF4CAF50)
                                        : Colors.grey,
                                    size: 22,
                                  ),
                                  if (_tags.isNotEmpty)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4CAF50),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${_tags.length}',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],

                        // Text field
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization:
                                TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                  color: Colors.grey.shade500),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Send button
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded,
                                color: Colors.black, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}