import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';

class EditProfileSheet extends StatefulWidget {
  final UserProfile profile;
  final bool focusBodyInfo;

  const EditProfileSheet({
    super.key,
    required this.profile,
    this.focusBodyInfo = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required UserProfile profile,
    bool focusBodyInfo = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ValimaiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditProfileSheet(
        profile: profile,
        focusBodyInfo: focusBodyInfo,
      ),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;
  late TextEditingController _targetWeightController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _weightController = TextEditingController(
      text: widget.profile.currentWeight.toStringAsFixed(1),
    );
    _heightController = TextEditingController(
      text: widget.profile.height.toInt().toString(),
    );
    _ageController = TextEditingController(
      text: widget.profile.age.toString(),
    );
    _targetWeightController = TextEditingController(
      text: widget.profile.targetWeight != null
          ? widget.profile.targetWeight!.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final age = int.tryParse(_ageController.text.trim());
    final targetWeightText = _targetWeightController.text.trim();
    final bool clearTargetWeight = targetWeightText.isEmpty;
    final double? targetWeight =
        clearTargetWeight ? null : double.tryParse(targetWeightText);

    final success = await ProfileController.instance.updateProfile(
      name: name,
      currentWeight: weight,
      height: height,
      age: age,
      targetWeight: targetWeight,
      clearTargetWeight: clearTargetWeight,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = ProfileController.instance.errorMessage ??
            'Failed to update profile. Please verify your entries.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ValimaiColors.secondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profile Information',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: ValimaiColors.secondary),
                    onPressed: () => Navigator.of(context).pop(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ValimaiColors.primaryContainer.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ValimaiColors.primaryContainer.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ValimaiColors.primaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Full Name
              _buildLabel('FULL NAME', isRequired: true),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _nameController,
                hint: 'Full Name',
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
              const SizedBox(height: 14),

              // Row 1: Weight & Height
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('WEIGHT (KG)', isRequired: true),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _weightController,
                          hint: 'Weight',
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('HEIGHT (CM)', isRequired: true),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _heightController,
                          hint: 'Height',
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
              const SizedBox(height: 14),

              // Row 2: Age & Target Weight
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('AGE (YEARS)', isRequired: true),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _ageController,
                          hint: 'Age',
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('TARGET WT (OPTIONAL)', isRequired: false),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _targetWeightController,
                          hint: 'Leave blank to clear',
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
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
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
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
            ],
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
          fontSize: 12,
          color: ValimaiColors.secondary.withOpacity(0.5),
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: ValimaiColors.secondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

