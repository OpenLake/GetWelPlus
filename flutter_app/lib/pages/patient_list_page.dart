import 'package:flutter/material.dart';
import 'package:flutter_app/models/patient_model.dart';
import 'package:flutter_app/widgets/patient_card.dart';
import 'package:flutter_app/pages/patient_detail_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  List<Patient> _patients = [];
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('patient_profiles')
          .select()
          .eq('onboarding_complete', true)
          .order('updated_at', ascending: false);

      setState(() {
        _patients = (response as List)
            .map((json) => Patient.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching patients: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient List'),
        centerTitle: true,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : _patients.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 52, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No patients yet',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _patients.length,
                  itemBuilder: (context, index) => PatientCard(
                    patient: _patients[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientDetailPage(
                          patient: _patients[index],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}