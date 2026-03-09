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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
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

                    // Feature List
                    FeatureCard(
                      imagePath: 'assets/images/online_call.jpg',
                      title: '1:1 Online Meet',
                      subtitle: 'Talk privately with a psychiatrist online',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlineMeetPage())),
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiChatPage()),
            );
          },
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