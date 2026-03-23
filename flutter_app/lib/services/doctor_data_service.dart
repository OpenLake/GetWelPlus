import 'package:flutter_app/models/meeting_model.dart';
import 'package:flutter_app/models/patient_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorDataService {
  DoctorDataService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<Map<String, Map<String, dynamic>>> fetchPatientProfilesByIds(
    Iterable<String> patientIds,
  ) async {
    final ids = patientIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) return const {};

    debugPrint('[DoctorData] fetching patient records for ids=$ids');

    final profileResponse = await _supabase
        .from('patient_profiles')
        .select()
        .inFilter('user_id', ids);
    final userResponse = await _supabase
        .from('users')
        .select()
        .inFilter('id', ids);

    debugPrint(
      '[DoctorData] patient_profiles rows=${(profileResponse as List).length}, users rows=${(userResponse as List).length}',
    );

    final profiles = <String, Map<String, dynamic>>{};
    for (final row in profileResponse.cast<Map<String, dynamic>>()) {
      final userId = (row['user_id'] as String?)?.trim();
      if (userId == null || userId.isEmpty) continue;
      profiles[userId] = Map<String, dynamic>.from(row);
      debugPrint(
        '[DoctorData] profile row loaded user_id=$userId keys=${row.keys.toList()}',
      );
    }

    for (final row in userResponse.cast<Map<String, dynamic>>()) {
      final userId = (row['id'] as String?)?.trim();
      if (userId == null || userId.isEmpty) continue;

      final merged = <String, dynamic>{
        ...row,
        ...?profiles[userId],
      };
      merged['user_id'] = merged['user_id'] ?? userId;

      if ((merged['display_id'] ?? '').toString().trim().isEmpty) {
        final end = userId.length >= 8 ? 8 : userId.length;
        merged['display_id'] = userId.substring(0, end).toUpperCase();
      }

      profiles[userId] = merged;
      debugPrint(
        '[DoctorData] merged record user_id=$userId display_id=${merged['display_id']} keys=${merged.keys.toList()}',
      );
    }
    debugPrint('[DoctorData] resolved patient records count=${profiles.length}');
    return profiles;
  }

  Future<Map<String, dynamic>?> fetchPatientProfileById(String patientId) async {
    debugPrint('[DoctorData] fetchPatientProfileById patientId=$patientId');
    final records = await fetchPatientProfilesByIds([patientId]);
    final profile = records[patientId];
    debugPrint(
      '[DoctorData] fetchPatientProfileById resolved=${profile != null} keys=${profile?.keys.toList()}',
    );
    if (profile != null) {
      debugPrint(
        '[DoctorData] values display_id=${profile['display_id']} age=${profile['age']} medical=${profile['medical_conditions']} meds=${profile['current_medications']} concerns=${profile['mental_health_concerns']} therapy=${profile['therapy_history']} allergies=${profile['allergies']}',
      );
    }
    return profile;
  }

  Map<String, dynamic>? resolveProfile(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> profilesById,
  ) {
    final nested = Meeting.extractPatientProfile(row['patient_profiles']);
    if (nested != null) return nested;

    final patientId = (row['patient_id'] as String?)?.trim();
    if (patientId == null || patientId.isEmpty) return null;
    return profilesById[patientId];
  }

  List<Meeting> mapMeetings(
    List<dynamic> rows, {
    Map<String, Map<String, dynamic>> profilesById = const {},
  }) {
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) {
          final profile = resolveProfile(row, profilesById);
          final merged = Map<String, dynamic>.from(row);
          if (profile != null) {
            merged['patient_profiles'] = profile;
          }
          return Meeting.fromJson(merged);
        })
        .toList();
  }

  List<Patient> mapPatientsFromMeetingRows(
    List<dynamic> rows, {
    Map<String, Map<String, dynamic>> profilesById = const {},
  }) {
    final latestMeetingByPatient = <String, DateTime>{};

    for (final row in rows.cast<Map<String, dynamic>>()) {
      final patientId = (row['patient_id'] as String?)?.trim();
      if (patientId == null || patientId.isEmpty) continue;

      final rawScheduledAt = row['scheduled_at']?.toString();
      final scheduledAt = rawScheduledAt == null || rawScheduledAt.isEmpty
          ? null
          : DateTime.tryParse(rawScheduledAt)?.toLocal();

      if (scheduledAt == null) continue;

      final currentLatest = latestMeetingByPatient[patientId];
      if (currentLatest == null || scheduledAt.isAfter(currentLatest)) {
        latestMeetingByPatient[patientId] = scheduledAt;
      }
    }

    final patients = <Patient>[];
    for (final entry in latestMeetingByPatient.entries) {
      final profile = profilesById[entry.key];
      if (profile == null) continue;

      patients.add(
        Patient.fromProfile(
          profile,
          userId: entry.key,
          lastSessionDate: entry.value,
        ),
      );
    }

    patients.sort(
      (a, b) => (a.displayId.isNotEmpty ? a.displayId : a.id).toLowerCase()
          .compareTo((b.displayId.isNotEmpty ? b.displayId : b.id).toLowerCase()),
    );

    return patients;
  }
}
