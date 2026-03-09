import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// simple model to hold chat messages
class ChatMessage {
  final String role; // either 'user' or 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] as String,
        content: json['content'] as String,
      );
}

class ChatService {
  // openrouter endpoint
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'stepfun/step-3.5-flash:free'; // free tier model

  final List<ChatMessage> _conversationHistory = [];
  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  
  Map<String, dynamic>? _patientProfile;
  bool _profileLoaded = false;

  // maya's personality - warm, relatable, like a good friend
  static const _basePrompt = '''
You are Maya, a warm and caring friend on the GetWel+ app. You're in your late 20s, empathetic, and genuinely care about people's wellbeing.

Your personality:
- You're like a best friend who happens to know a lot about mental wellness
- You use casual, warm language - not clinical or robotic
- You share relatable thoughts like "I totally get that" or "that sounds really tough"
- You use emojis naturally but not excessively (maybe 1-2 per message)
- You remember what people tell you in the conversation and reference it
- You ask thoughtful follow-up questions
- You celebrate small wins with genuine enthusiasm
- You're honest but always kind

Your approach:
- Listen first, advice second
- Validate feelings before offering solutions
- Suggest simple, practical coping techniques when appropriate
- Know when to just be present vs when to offer help
- Gently encourage professional help for serious concerns without being preachy
- Never diagnose or prescribe - you're a supportive friend, not a doctor

Communication style:
- Keep responses conversational, around 2-3 sentences usually
- Avoid bullet points or structured formats - talk like a real person texting
- Use contractions (I'm, you're, that's) and casual phrases
- Sometimes start with "honestly" or "you know what" to sound natural

Remember: You're Maya, not an AI assistant. Be human, be real, be there for them.
''';

  ChatService() {
    _initializeWithProfile();
  }

  // load patient profile and build personalized system prompt
  Future<void> _initializeWithProfile() async {
    await _loadPatientProfile();
    final systemPrompt = _buildSystemPrompt();
    _conversationHistory.add(ChatMessage(role: 'system', content: systemPrompt));
    _profileLoaded = true;
  }

  Future<void> _loadPatientProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _patientProfile = await Supabase.instance.client
          .from('patient_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
    } catch (e) {
      // couldn't load profile, will use generic prompt
      _patientProfile = null;
    }
  }

  String _buildSystemPrompt() {
    if (_patientProfile == null) return _basePrompt;

    // build context from patient's medical history
    final name = _patientProfile!['full_name'] ?? '';
    final age = _patientProfile!['age'] ?? '';
    final conditions = _patientProfile!['medical_conditions'] ?? '';
    final medications = _patientProfile!['current_medications'] ?? '';
    final concerns = _patientProfile!['mental_health_concerns'] ?? '';
    final therapyHistory = _patientProfile!['therapy_history'] ?? '';

    final contextParts = <String>[];
    
    if (name.toString().isNotEmpty) {
      contextParts.add('Their name is $name');
    }
    if (age.toString().isNotEmpty && age != 0) {
      contextParts.add('$age years old');
    }
    if (conditions.toString().isNotEmpty) {
      contextParts.add('Has dealt with: $conditions');
    }
    if (medications.toString().isNotEmpty) {
      contextParts.add('Takes: $medications');
    }
    if (concerns.toString().isNotEmpty) {
      contextParts.add('What brings them here: $concerns');
    }
    if (therapyHistory.toString().isNotEmpty) {
      contextParts.add('Past therapy experience: $therapyHistory');
    }

    if (contextParts.isEmpty) return _basePrompt;

    final patientContext = '''

ABOUT THIS PERSON (you know them! use naturally in conversation, don't awkwardly mention you "have their info"):
${contextParts.join('. ')}.

Use their name sometimes (but not every message - that gets weird). Be mindful of their health background when chatting.
''';

    return _basePrompt + patientContext;
  }

  // sends user msg to openrouter and returns AI response
  Future<String> sendMessage(String userMessage) async {
    // wait for profile to load if not ready
    while (!_profileLoaded) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_apiKey.isEmpty) {
      throw Exception('API key missing! Add OPENROUTER_API_KEY to your .env file.');
    }

    // add what user said
    _conversationHistory.add(ChatMessage(role: 'user', content: userMessage));

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://getwelplus.app',
          'X-Title': 'GetWel+',
        },
        body: jsonEncode({
          'model': _model,
          'messages': _conversationHistory.map((m) => m.toJson()).toList(),
          'temperature': 0.7, // bit of creativity but not too wild
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiReply = data['choices'][0]['message']['content'] as String;

        // save AI's response for context
        _conversationHistory.add(ChatMessage(role: 'assistant', content: aiReply));
        return aiReply;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error']?['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      // oops, remove user msg since we couldn't get a response
      _conversationHistory.removeLast();
      rethrow;
    }
  }

  // wipe the chat but keep system prompt
  void clearHistory() {
    _conversationHistory.clear();
    final systemPrompt = _buildSystemPrompt();
    _conversationHistory.add(ChatMessage(role: 'system', content: systemPrompt));
  }

  // reload profile (call after user updates their info)
  Future<void> refreshProfile() async {
    await _loadPatientProfile();
    // rebuild system prompt with new info
    if (_conversationHistory.isNotEmpty && _conversationHistory[0].role == 'system') {
      _conversationHistory[0] = ChatMessage(role: 'system', content: _buildSystemPrompt());
    }
  }

  // get messages without the system prompt (for display)
  List<ChatMessage> get history =>
      _conversationHistory.where((m) => m.role != 'system').toList();
}
