import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/daily_workout_controller.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import 'daily_workout_selection_screen.dart';
import 'main_shell.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();

  bool _isSaving = false;
  String? _generalError;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    setState(() {
      _generalError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final height = double.tryParse(_heightController.text.trim()) ?? 0.0;
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final targetWeightText = _targetWeightController.text.trim();
    final double? targetWeight = targetWeightText.isNotEmpty
        ? double.tryParse(targetWeightText)
        : null;

    final success = await ProfileController.instance.saveProfile(
      name: name,
      currentWeight: weight,
      height: height,
      age: age,
      targetWeight: targetWeight,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      if (!DailyWorkoutController.instance.hasDecisionForToday()) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                const DailyWorkoutSelectionScreen(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      } else {
        // Navigate to Home Dashboard
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainShell(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } else {
      setState(() {
        _generalError = ProfileController.instance.errorMessage ??
            'Failed to save profile. Please check your inputs.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ValimaiColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Centered Header & Logo (Application name removed, logo kept)
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: ValimaiColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3DF02D36),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.bolt,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Profile Setup',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: ValimaiColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Configure your baseline biometrics to calibrate your telemetry and tracking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            color: ValimaiColors.secondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // General error banner if present
                  if (_generalError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ValimaiColors.primaryContainer.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ValimaiColors.primaryContainer.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: ValimaiColors.primaryContainer,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _generalError!,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ValimaiColors.primaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Field: Name
                  _buildLabel('FULL NAME', isRequired: true),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'e.g. Alex Mercer',
                    icon: Icons.person_outline,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Name cannot be empty';
                      }
                      if (val.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Field Row: Weight & Height
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weight
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('WEIGHT (KG)', isRequired: true),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: _weightController,
                              hint: '75.0',
                              icon: Icons.scale_outlined,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,1}'),
                                ),
                              ],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                final num = double.tryParse(val.trim());
                                if (num == null ||
                                    num < UserProfile.minWeight ||
                                    num > UserProfile.maxWeight) {
                                  return '${UserProfile.minWeight.toInt()}–${UserProfile.maxWeight.toInt()} kg';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Height
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('HEIGHT (CM)', isRequired: true),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: _heightController,
                              hint: '180',
                              icon: Icons.straighten_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                final num = double.tryParse(val.trim());
                                if (num == null ||
                                    num < UserProfile.minHeight ||
                                    num > UserProfile.maxHeight) {
                                  return '${UserProfile.minHeight.toInt()}–${UserProfile.maxHeight.toInt()} cm';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Field Row: Age & Target Weight (Optional)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Age
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('AGE (YEARS)', isRequired: true),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: _ageController,
                              hint: '26',
                              icon: Icons.calendar_today_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                final num = int.tryParse(val.trim());
                                if (num == null ||
                                    num < UserProfile.minAge ||
                                    num > UserProfile.maxAge) {
                                  return '${UserProfile.minAge}–${UserProfile.maxAge} yrs';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Target Weight
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('TARGET WT (OPTIONAL)', isRequired: false),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: _targetWeightController,
                              hint: '80.0',
                              icon: Icons.flag_outlined,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,1}'),
                                ),
                              ],
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  final num = double.tryParse(val.trim());
                                  if (num == null ||
                                      num < UserProfile.minWeight ||
                                      num > UserProfile.maxWeight) {
                                    return '${UserProfile.minWeight.toInt()}–${UserProfile.maxWeight.toInt()} kg';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Prominent Red Save Profile Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ValimaiColors.primaryContainer,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            ValimaiColors.primaryContainer.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'SAVE PROFILE',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Center(
                    child: Text(
                      'Information is stored securely and offline on your device.',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: ValimaiColors.secondary,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ValimaiColors.primaryContainer,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ValimaiColors.onSurface,
      ),
      cursorColor: ValimaiColors.primaryContainer,
      decoration: InputDecoration(
        filled: true,
        fillColor: ValimaiColors.surfaceContainerLow,
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
          color: ValimaiColors.secondary.withOpacity(0.6),
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: ValimaiColors.secondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ValimaiColors.cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: ValimaiColors.primaryContainer,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: ValimaiColors.primaryContainer,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: ValimaiColors.primaryContainer,
            width: 1.5,
          ),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ValimaiColors.primaryContainer,
        ),
      ),
    );
  }
}

