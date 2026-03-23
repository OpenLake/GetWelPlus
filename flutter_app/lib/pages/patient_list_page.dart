import 'package:flutter/material.dart';
import 'package:flutter_app/core/error_messages.dart';
import 'package:flutter_app/models/patient_model.dart';
import 'package:flutter_app/services/doctor_data_service.dart';
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
  late final DoctorDataService _doctorDataService;

  @override
  void initState() {
    super.initState();
    _doctorDataService = DoctorDataService(client: _supabase);
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
      return patient.displayId.toLowerCase().contains(lowerQuery) ||
          patient.id.toLowerCase().contains(lowerQuery) ||
          patient.email.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final meetingRows = await _supabase
          .from('meetings')
          .select('patient_id, scheduled_at, status')
          .inFilter('status', ['pending', 'confirmed', 'completed']);

      final typedRows = (meetingRows as List).cast<Map<String, dynamic>>();
      final meetingCount = typedRows.length;
      debugPrint('[PatientList] meeting rows fetched: $meetingCount');

      final profilesById = await _doctorDataService.fetchPatientProfilesByIds(
        typedRows
            .map((row) => (row['patient_id'] ?? '').toString())
            .where((id) => id.isNotEmpty),
      );

      debugPrint(
        '[PatientList] patient profiles resolved: ${profilesById.length}',
      );

      if (profilesById.isEmpty) {
        setState(() {
          _patients = [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _patients = _doctorDataService.mapPatientsFromMeetingRows(
          typedRows,
          profilesById: profilesById,
        );
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('[PatientList] Error fetching patients: $e');
      debugPrint(stackTrace.toString());
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error fetching patients: ${friendlyErrorMessage(e)}',
            ),
          ),
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
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by ID, user ID, or email',
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
                              Icon(
                                Icons.people_outline,
                                size: 52,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No patients found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
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
                                  builder: (_) =>
                                      PatientDetailPage(patient: patient),
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
