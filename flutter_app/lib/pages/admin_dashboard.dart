import 'package:flutter/material.dart';
import 'package:flutter_app/auth/auth_service.dart';
import 'package:flutter_app/widgets/feature_card.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GetWel+', style: TextStyle(fontSize: 31)),
          elevation: 4,
          centerTitle: true,
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
                        const Expanded(
                          child: Text(
                            'Doctor',
                            style: TextStyle(
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, Doctor 👋',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600, fontSize: 26),
              ),
              const SizedBox(height: 20),

              FeatureCard(
                imagePath: 'assets/images/online_call.jpg',
                title: 'Meeting Requests',
                subtitle: 'View incoming meeting requests',
                onTap: () {},
              ),
              FeatureCard(
                imagePath: 'assets/images/book_a_slot.jpg',
                title: 'Scheduled Meetings',
                subtitle: 'View your upcoming confirmed meetings',
                onTap: () {},
              ),
              FeatureCard(
                imagePath: 'assets/images/articles.jpg',
                title: 'Past Meetings',
                subtitle: 'View history of completed sessions',
                onTap: () {},
              ),
              FeatureCard(
                imagePath: 'assets/images/mood.jpg',
                title: 'Patient List',
                subtitle: 'View and manage your patients',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}