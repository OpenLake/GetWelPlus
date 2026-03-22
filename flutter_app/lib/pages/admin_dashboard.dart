import 'package:flutter/material.dart';
import 'package:flutter_app/auth/auth_service.dart';
import 'package:flutter_app/pages/admin_maya_chat_page.dart';
import 'package:flutter_app/pages/past_meetings_page.dart';
import 'package:flutter_app/pages/patient_list_page.dart';
import 'package:flutter_app/widgets/feature_card.dart';
import 'package:flutter_app/pages/meeting_requests_page.dart';
import 'package:flutter_app/pages/scheduled_meetings_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Widget _buildInsightCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily practice tip',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Text('Review pending patient requests and follow up on any high-risk mood alerts.',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

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
              const SizedBox(height: 12),
              _buildInsightCard(context),
              const SizedBox(height: 20),

              FeatureCard(
                imagePath: 'assets/images/online_call.jpg',
                title: 'Meeting Requests',
                subtitle: 'View incoming meeting requests',
                onTap: () => Navigator.push(context,MaterialPageRoute(builder: (_) => const MeetingRequestsPage()),),
              ),
              FeatureCard(
                imagePath: 'assets/images/book_a_slot.jpg',
                title: 'Scheduled Meetings',
                subtitle: 'View your upcoming confirmed meetings',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_)=> const ScheduledMeetingsPage())),
              ),
              FeatureCard(
                imagePath: 'assets/images/articles.jpg',
                title: 'Past Meetings',
                subtitle: 'View history of completed sessions',
                onTap: () => Navigator.push(context,  MaterialPageRoute(builder: (_)=> const PastMeetingsPage())),
              ),
              FeatureCard(
                imagePath: 'assets/images/mood.jpg',
                title: 'Patient List',
                subtitle: 'View and manage your patients',
                onTap: ()=> Navigator.push(context, MaterialPageRoute(builder:(_) => const PatientListPage())),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminMayaChatPage(),
              ),
            );
          },
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child: Text(
              'M',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          label: const Text(
            'Chat with Maya',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}