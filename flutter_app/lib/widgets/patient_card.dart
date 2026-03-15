import 'package:flutter/material.dart';
import 'package:flutter_app/models/patient_model.dart';
import 'package:intl/intl.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const PatientCard({
    super.key,
    required this.patient,
    required this.onTap,
  });

  String get _displayName =>
      patient.displayId.isNotEmpty ? patient.displayId : patient.name;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar — shows first char of displayId
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF4CAF50).withOpacity(0.15),
                child: Text(
                  _displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display ID
                    Text(
                      _displayName,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 4),

                    // Age + gender
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          '${patient.age} years old · ${patient.gender}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Last session
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined,
                            size: 13, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 5),
                        Text(
                          'Last session: ${DateFormat('MMM d, yyyy').format(patient.lastSessionDate)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF4CAF50)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}