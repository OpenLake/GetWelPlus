import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/error_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // controllers for editing
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _mentalHealthController = TextEditingController();
  final _therapyHistoryController = TextEditingController();

  String _selectedGender = 'Prefer not to say';
  final _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _mentalHealthController.dispose();
    _therapyHistoryController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('patient_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profile = data;
          _isLoading = false;
          if (data != null) _populateControllers(data);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${friendlyErrorMessage(e)}')),
        );
      }
    }
  }

  void _populateControllers(Map<String, dynamic> data) {
    _nameController.text = data['full_name'] ?? '';
    _ageController.text = (data['age'] ?? '').toString();
    _phoneController.text = data['phone'] ?? '';
    _emergencyNameController.text = data['emergency_contact_name'] ?? '';
    _emergencyPhoneController.text = data['emergency_contact_phone'] ?? '';
    _conditionsController.text = data['medical_conditions'] ?? '';
    _medicationsController.text = data['current_medications'] ?? '';
    _allergiesController.text = data['allergies'] ?? '';
    _mentalHealthController.text = data['mental_health_concerns'] ?? '';
    _therapyHistoryController.text = data['therapy_history'] ?? '';
    _selectedGender = data['gender'] ?? 'Prefer not to say';
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // use update since profile already exists
      await Supabase.instance.client.from('patient_profiles').update({
        'full_name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _selectedGender,
        'phone': _phoneController.text.trim(),
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'medical_conditions': _conditionsController.text.trim(),
        'current_medications': _medicationsController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'mental_health_concerns': _mentalHealthController.text.trim(),
        'therapy_history': _therapyHistoryController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', user.id);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        _loadProfile(); // refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e, fallback: 'Something went wrong. Please try again.')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isLoading && _profile != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
              onPressed: () {
                if (_isEditing) {
                  // cancel editing, restore original values
                  _populateControllers(_profile!);
                }
                setState(() => _isEditing = !_isEditing);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? _buildNoProfile(colorScheme)
              : _buildProfileView(colorScheme),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveProfile,
              backgroundColor: colorScheme.primary,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
            )
          : null,
    );
  }

  Widget _buildNoProfile(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No profile found'),
          const SizedBox(height: 8),
          Text(
            'Complete onboarding to set up your profile',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // user ID card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    (_profile?['full_name'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _profile?['full_name'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _profile?['display_id'] ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ID copied!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          'ID: ${_profile?['display_id'] ?? 'N/A'}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy, size: 14, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // basic info section
          _buildSection(
            title: 'Basic Information',
            icon: Icons.person_outline,
            colorScheme: colorScheme,
            children: [
              _buildField('Full Name', _nameController, Icons.person_outline),
              _buildFieldRow([
                _buildField('Age', _ageController, Icons.cake_outlined, keyboardType: TextInputType.number),
                _buildDropdownField('Gender', colorScheme),
              ]),
              _buildField('Phone', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
            ],
          ),

          const SizedBox(height: 16),

          // emergency contact
          _buildSection(
            title: 'Emergency Contact',
            icon: Icons.contact_emergency_outlined,
            colorScheme: colorScheme,
            children: [
              _buildField('Contact Name', _emergencyNameController, Icons.person_outline),
              _buildField('Contact Phone', _emergencyPhoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
            ],
          ),

          const SizedBox(height: 16),

          // medical history
          _buildSection(
            title: 'Medical History',
            icon: Icons.medical_information_outlined,
            colorScheme: colorScheme,
            children: [
              _buildField('Medical Conditions', _conditionsController, Icons.medical_information_outlined, maxLines: 2),
              _buildField('Current Medications', _medicationsController, Icons.medication_outlined, maxLines: 2),
              _buildField('Allergies', _allergiesController, Icons.warning_amber_outlined, maxLines: 2),
            ],
          ),

          const SizedBox(height: 16),

          // mental health
          _buildSection(
            title: 'Mental Health',
            icon: Icons.psychology_outlined,
            colorScheme: colorScheme,
            children: [
              _buildField('Current Concerns', _mentalHealthController, Icons.psychology_outlined, maxLines: 3),
              _buildField('Therapy History', _therapyHistoryController, Icons.history_outlined, maxLines: 3),
            ],
          ),

          const SizedBox(height: 100), // space for FAB
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _isEditing
          ? TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.text.isEmpty ? 'Not provided' : controller.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: controller.text.isEmpty ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFieldRow(List<Widget> children) {
    return Row(
      children: children
          .map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w)))
          .toList(),
    );
  }

  Widget _buildDropdownField(String label, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _isEditing
          ? DropdownButtonFormField<String>(
              value: _selectedGender,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _genderOptions.map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) => setState(() => _selectedGender = v!),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.wc_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 2),
                      Text(_selectedGender, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
