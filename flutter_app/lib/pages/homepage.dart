import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/auth/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/widgets/feature_card.dart';

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
    return Scaffold(
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
        padding: const EdgeInsets.all(16.0),
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
            imagePath: "assets/images/mood.jpg",
            title: 'Track your mood',
            subtitle: 'Log how you’re feeling today',
            onTap: () {
              // navigate to mood tracker page
            },
          ),
            // SizedBox(height: 20,),
            FeatureCard(
              imagePath: 'assets/images/meditation.jpg',
              title: 'Guided Meditation',
              subtitle: 'Relax your mind in just a few minutes',
              onTap: () {
                // open meditation page
              },
            ),
            FeatureCard(
              imagePath: 'assets/images/stress.jpg',
              title: 'Stress Check',
              subtitle: 'Measure your stress level in minutes',
              onTap: () {
                // open stress test page
              },
            ),
            FeatureCard(
              imagePath: 'assets/images/music.jpg',
              title: 'Calm Music',
              subtitle: 'Soothing sounds to relax your mind',
              onTap: () {
                // open calm music / audio page
              },
            ),       

          ]
        ),
      ),



    );
  }
}
