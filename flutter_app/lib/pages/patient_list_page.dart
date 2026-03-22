import 'package:flutter/material.dart';
import 'package:flutter_app/core/error_messages.dart';
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
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Patient> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    final lowerQuery = _searchQuery.toLowerCase();
    return _patients.where((patient) {
      return patient.name.toLowerCase().contains(lowerQuery) ||
          patient.displayId.toLowerCase().contains(lowerQuery) ||
          patient.email.toLowerCase().contains(lowerQuery);
    }).toList();
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
          SnackBar(content: Text('Error fetching patients: ${friendlyErrorMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _filteredPatients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient List'),
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload patients',
            onPressed: _fetchPatients,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by name, ID, or email',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                Expanded(
                  child: displayed.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline, size: 52, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No patients found',
                                style: TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayed.length,
                          itemBuilder: (context, index) {
                            final patient = displayed[index];
                            return PatientCard(
                              patient: patient,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PatientDetailPage(patient: patient),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
