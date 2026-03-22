import 'package:flutter/material.dart';
import 'package:flutter_app/core/error_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // form controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _mentalHealthController = TextEditingController();
  final _therapyHistoryController = TextEditingController();

  String _selectedGender = 'Prefer not to say';
  bool _isLoading = false;

  final _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _mentalHealthController.dispose();
    _therapyHistoryController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // save to patient_profiles table
      await Supabase.instance.client.from('patient_profiles').upsert({
        'user_id': user.id,
        'display_id': user.id.substring(0, 8).toUpperCase(), // short readable ID
        'full_name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _selectedGender,
        'phone': _phoneController.text.trim(),
        'emergency_contact_name': _emergencyContactController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'medical_conditions': _conditionsController.text.trim(),
        'current_medications': _medicationsController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'mental_health_concerns': _mentalHealthController.text.trim(),
        'therapy_history': _therapyHistoryController.text.trim(),
        'onboarding_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e, fallback: 'Something went wrong. Please try again.')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Welcome to GetWel+',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let\'s set up your profile',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? colorScheme.primary
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              // pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildBasicInfoPage(colorScheme),
                    _buildMedicalHistoryPage(colorScheme),
                    _buildPrivacyPage(colorScheme),
                  ],
                ),
              ),

              // navigation buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevPage,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: colorScheme.primary),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : (_currentPage == 2 ? _submitForm : _nextPage),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.primary,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_currentPage == 2 ? 'Get Started' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Basic Information'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _ageController,
                  label: 'Age',
                  hint: '25',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    final age = int.tryParse(v);
                    if (age == null || age < 13 || age > 120) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Gender',
                  value: _selectedGender,
                  items: _genderOptions,
                  onChanged: (v) => setState(() => _selectedGender = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+91 9876543210',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          _sectionTitle('Emergency Contact'),
          const SizedBox(height: 8),
          Text(
            'Someone we can reach in case of emergency',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emergencyContactController,
            label: 'Contact Name',
            hint: 'Parent, spouse, friend...',
            icon: Icons.contact_emergency_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emergencyPhoneController,
            label: 'Contact Phone',
            hint: '+91 9876543210',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryPage(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Medical History'),
          const SizedBox(height: 8),
          Text(
            'This helps our AI give you more personalized support',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _conditionsController,
            label: 'Medical Conditions',
            hint: 'Diabetes, hypertension, etc. (if any)',
            icon: Icons.medical_information_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _medicationsController,
            label: 'Current Medications',
            hint: 'List any medications you take regularly',
            icon: Icons.medication_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _allergiesController,
            label: 'Allergies',
            hint: 'Drug allergies, food allergies, etc.',
            icon: Icons.warning_amber_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          _sectionTitle('Mental Health Background'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _mentalHealthController,
            label: 'Current Concerns',
            hint: 'What brings you here? Anxiety, stress, sleep issues...',
            icon: Icons.psychology_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _therapyHistoryController,
            label: 'Previous Therapy/Treatment',
            hint: 'Have you seen a therapist before? Any past diagnoses?',
            icon: Icons.history_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPage(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.security,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _privacyPoint(
                  Icons.lock_outline,
                  'End-to-end encryption',
                  'Your data is encrypted and stored securely',
                  colorScheme,
                ),
                _privacyPoint(
                  Icons.visibility_off_outlined,
                  'No data sharing',
                  'We never sell or share your personal info',
                  colorScheme,
                ),
                _privacyPoint(
                  Icons.person_outline,
                  'Manual review only',
                  'Only verified professionals access data when needed',
                  colorScheme,
                ),
                _privacyPoint(
                  Icons.delete_outline,
                  'Your control',
                  'Delete your data anytime from settings',
                  colorScheme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This app is for support only and does not replace professional medical advice.',
                    style: TextStyle(
                      color: Colors.amber[800],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _privacyPoint(
    IconData icon,
    String title,
    String subtitle,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((e) => DropdownMenuItem(
        value: e,
        child: Text(e, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: onChanged,
    );
  }
}
