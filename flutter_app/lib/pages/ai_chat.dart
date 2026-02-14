import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/chat_bubble.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {

  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {"text": "message from ai", "isUser": false},
    {"text": "message from user", "isUser": true},
    {"text": "message from ai but this is longer to check ui wrapping properly", "isUser": false},
  ];

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        "text": text,
        "isUser": true,
      });
    });

    _messageController.clear();

    /// Simulated AI reply (temporary)
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _messages.add({
          "text": "AI response placeholder",
          "isUser": false,
        });
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chat"),
        centerTitle: true,
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [

            /// Messages Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];

                    return ChatBubble(
                      message: message["text"],
                      isUser: message["isUser"],
                    );
                  },
                ),
              ),
            ),

            /// Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

              child: Row(
                children: [

                  /// Real Text Field
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.black),
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        hintStyle: TextStyle(color: Colors.black),
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

                  /// Send Button
                  Material(
                    color: Colors.green,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.black,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
