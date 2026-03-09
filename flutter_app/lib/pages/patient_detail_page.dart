import 'package:flutter/material.dart';
import 'package:flutter_app/models/patient_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/widgets/feature_card.dart';

class PatientDetailPage extends StatelessWidget {
  final Patient patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patient.name),
        centerTitle: true,
        elevation: 4,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
// Profile header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.15),
                      child: Text(
                        patient.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      patient.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient.age} years old',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Column(
                  children: [
                    _infoRow(context, Icons.email_outlined, 'Email', patient.email),
                    const Divider(height: 24),
                    _infoRow(context, Icons.phone_outlined, 'Phone', patient.phone),
                    const Divider(height: 24),
                    _infoRow(
                      context,
                      Icons.access_time_outlined,
                      'Last Session',
                      DateFormat('MMM d, yyyy').format(patient.lastSessionDate),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              FeatureCard(
                imagePath: 'assets/images/articles.jpg',
                title: 'Past Interactions',
                subtitle: 'View all previous sessions and notes',
                onTap: () {
                  // TODO: navigate to past interactions page later
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xFF4CAF50)),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ],
  );
}