import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/chat_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorChatPage extends StatefulWidget {
  final String meetingId;

  const DoctorChatPage({
    super.key,
    required this.meetingId,
  });

  @override
  State<DoctorChatPage> createState() => _DoctorChatPageState();
}

class _DoctorChatPageState extends State<DoctorChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _subscribeToMessages();
  }

  // Fetch existing messages for this meeting
  Future<void> _fetchMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('meeting_id', widget.meetingId)
          .order('created_at', ascending: true);

      setState(() {
        _messages = (response as List)
            .map((m) => {
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

  // Listen for new messages in real time
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
            // Avoid adding duplicate if it's our own message
            final isUser = newMessage['sender_id'] == _currentUserId;
            if (!isUser) {
              setState(() {
                _messages.add({
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

  // Insert message into Supabase
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Optimistically add to UI immediately
    setState(() {
      _messages.add({'text': text, 'isUser': true});
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
      // Remove optimistic message if insert failed
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet.\nSay hello! 👋',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.grey, fontSize: 15),
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
                      top: BorderSide(color: Colors.grey.shade800),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle:
                                  TextStyle(color: Colors.grey.shade500),
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
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
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