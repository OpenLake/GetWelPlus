import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/auth/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/widgets/feature_card.dart';
import 'package:flutter_app/pages/stress_check_page.dart';
import 'package:flutter_app/pages/article_page.dart';
import 'package:flutter_app/pages/mood_tracker.dart';
import 'package:flutter_app/pages/ai_chat.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GetWel+',style: TextStyle(
            fontSize: 31
          ),),
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
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
      
                    final data = snapshot.data!;
                    final name = data['name'] ?? 'User';
      
                    return Column(
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
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 44,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
      
      
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // navigate to Profile page later
                },
              ),
      
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  // navigate to Settings page later
                },
              ),
      
              const Divider(),
      
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        ),
      
      
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
              
                    final data = snapshot.data!;
                    final name = data['name'] ?? 'User';
                    final greeting = getGreeting();
              
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $name 👋',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 23,
                              ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20,),
                FeatureCard(
                  imagePath: 'assets/images/online_call.jpg',
                  title: '1:1 Online Meet',
                  subtitle: 'Talk privately with a psychiatrist online',
                  onTap: () {
                    // navigate to online consultation flow later
                  },
                ),
            
              FeatureCard(
                imagePath: "assets/images/mood.jpg",
                title: 'Track your mood',
                subtitle: 'Log how you’re feeling today',
                onTap: () {
                  // navigate to mood tracker page
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MoodTrackerPage(),
                      ),
                    );
                },
              ),
                // SizedBox(height: 20,),
              FeatureCard(
                imagePath: 'assets/images/book_a_slot.jpg',
                title: 'Book a Session',
                subtitle: 'Meet a mental health professional offline',
                onTap: () {
                  // navigate to booking page later
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
                      );                // open stress test page
                  },
                ),   
                  FeatureCard(
                    imagePath: 'assets/images/articles.jpg',
                    title: 'Psychology Articles',
                    subtitle: 'Read expert-written articles to better understand your mind',
                    onTap: () {
                      // navigate to articles list page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ArticlesPage(),
                        ),
                      );

                    },
                  ),
            
            
              ]
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          shape: CircleBorder(),
          foregroundColor: Colors.black,
          onPressed: () {
            // Navigate to AI Chat screen later
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AiChatPage(),
                  ),
                );
          },
          backgroundColor: Colors.green,
          child: const Text("AI",style: TextStyle(fontSize: 27),),
        ),
      
      
      
      ),
    );
  }
}
