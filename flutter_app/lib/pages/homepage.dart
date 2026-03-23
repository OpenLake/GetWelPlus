import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Services and Providers
import 'package:flutter_app/auth/auth_service.dart';

// Feature Pages
import 'package:flutter_app/pages/stress_check_page.dart';
import 'package:flutter_app/pages/article_page.dart';
import 'package:flutter_app/pages/mood_tracker.dart';
import 'package:flutter_app/pages/online_meet_page.dart';
import 'package:flutter_app/pages/ai_chat.dart';
import 'package:flutter_app/pages/profile_page.dart';
import 'package:flutter_app/pages/chat_list_page.dart';
import 'package:flutter_app/pages/maya_consent_page.dart';

// Widgets
import 'package:flutter_app/widgets/feature_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final authService = AuthService();
  Map<String, dynamic>? userProfile;
  Map<String, dynamic>? patientProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadPatientProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final profile = await authService.getUserProfile(userId);
        if (mounted) {
          setState(() {
            userProfile = profile;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPatientProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final profile = await Supabase.instance.client
            .from('patient_profiles')
            .select('maya_data_consent')
            .eq('user_id', userId)
            .maybeSingle();
        if (mounted) {
          setState(() => patientProfile = profile);
        }
      }
    } catch (e) {
      // silent fail, will show consent page
    }
  }

  void _openMayaChat() {
    // check if user has already given consent
    final consent = patientProfile?['maya_data_consent'];
    
    if (consent == null) {
      // first time - show consent page
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MayaConsentPage()));
    } else {
      // already consented - go straight to chat
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AiChatPage(sharesMedicalData: consent == true)),
      );
    }
  }

  Future<void> _launchURL(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }
}

  static const List<String> _quotes = [
    'Every step forward counts — small habits become strong routines.',
    'You are your most important project. Be kind to yourself today.',
    'It is okay to pause, reflect, and then move with intention.',
    'A few deep breaths can reset your nervous system in minutes.',
  ];

  String _todayQuote() {
    final index = DateTime.now().day % _quotes.length;
    return _quotes[index];
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  void _startBreathingExercise(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('2-Minute Breathing Exercise'),
        content: const Text(
          'Try this simple calming practice:\n\n'
          '1. Inhale for 4 seconds\n'
          '2. Hold for 4 seconds\n'
          '3. Exhale for 6 seconds\n'
          '4. Repeat 5 times',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = userProfile?['name'] ?? user?.userMetadata?['name'] ?? 'User';

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GetWel+', style: TextStyle(fontSize: 31)),
          elevation: 4,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // open notifications page later
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 65, 151, 69),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.black,
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  await authService.signOut();
                },
              ),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${getGreeting()} 👋',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600, fontSize: 26),
                        ),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600, fontSize: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today’s wellness focus',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(_todayQuote(), style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _startBreathingExercise(context),
                              icon: const Icon(Icons.self_improvement_outlined),
                              label: const Text('Quick 2-min breathing'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Feature List
                    FeatureCard(
                      imagePath: 'assets/images/online_call.jpg',
                      title: '1:1 Online Meet',
                      subtitle: 'Talk privately with a psychiatrist online',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlineMeetPage())),
                    ),
                    FeatureCard(
                      imagePath: 'assets/images/articles.jpg',
                      title: '1:1 Chat',
                      subtitle: 'Chat privately with a psychiatrist',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListPage())),
                    ),
                    FeatureCard(
                      imagePath: "assets/images/mood.jpg",
                      title: 'Track your mood',
                      subtitle: 'Log how you\'re feeling today',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MoodTrackerPage(),
                          ),
                        );
                      },
                    ),
                    FeatureCard(
                      imagePath: 'assets/images/book_a_slot.jpg',
                      title: 'Book a Session',
                      subtitle: 'Meet a mental health professional offline',
                      onTap: () {
                        _launchURL('https://appointment.iitbhilai.ac.in/');
                      },
                    ),
                    FeatureCard(
                      imagePath: 'assets/images/stress.jpg',
                      title: 'Stress Check',
                      subtitle: 'Measure your stress level in minutes',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StressCheckPage(),
                          ),
                        );
                      },
                    ),
                    FeatureCard(
                      imagePath: 'assets/images/articles.jpg',
                      title: 'Psychology Articles',
                      subtitle: 'Read expert-written articles',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ArticlesPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openMayaChat,
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child: Text('M', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          label: const Text('Chat with Maya', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}