import 'package:flutter/material.dart';
import 'package:flutter_app/core/error_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/pages/ai_chat.dart';

class MayaConsentPage extends StatefulWidget {
  const MayaConsentPage({super.key});

  @override
  State<MayaConsentPage> createState() => _MayaConsentPageState();
}

class _MayaConsentPageState extends State<MayaConsentPage> {
  bool _isLoading = false;

  Future<void> _saveConsent(bool shareData) async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      await Supabase.instance.client.from('patient_profiles').update({
        'maya_data_consent': shareData,
        'maya_consent_date': DateTime.now().toIso8601String(),
      }).eq('user_id', user.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AiChatPage(sharesMedicalData: shareData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e, fallback: 'Something went wrong. Please try again.')),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Maya avatar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'M',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Hey, I\'m Maya! 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Before we chat, a quick question...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 32),

              // Main question card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Would you like me to know about your health background?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This includes your medical conditions, medications, and what brings you here. It helps me give more relevant support.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Privacy assurance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline,
                        color: colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your data stays private & encrypted. You can change this anytime in settings.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Buttons
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _saveConsent(true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.primary,
                        ),
                        child: const Text(
                          'Yes, personalize my experience',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _saveConsent(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: Text(
                          'No thanks, keep it general',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}