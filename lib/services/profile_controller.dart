import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import 'profile_storage.dart';

class ProfileController extends ChangeNotifier {
  static ProfileController? _instance;
  static ProfileController get instance {
    _instance ??= ProfileController();
    return _instance!;
  }

  // Allow resetting instance for testing
  @visibleForTesting
  static void setInstance(ProfileController controller) {
    _instance = controller;
  }

  final IProfileStorage _storage;

  UserProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  ProfileController({IProfileStorage? storage})
    : _storage = storage ?? LocalProfileStorage();

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Derive onboarding status reliably from saved profile
  bool get isOnboardingCompleted {
    return _profile != null && _profile!.isOnboardingCompleted;
  }

  /// Initialize and load profile from persistent local storage
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _storage.loadProfile();
    } catch (e) {
      _errorMessage = 'Failed to load profile from local storage.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save new profile during first-launch onboarding
  Future<bool> saveProfile({
    required String name,
    required double currentWeight,
    required double height,
    required int age,
    double? targetWeight,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Name cannot be empty.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (currentWeight < UserProfile.minWeight ||
        currentWeight > UserProfile.maxWeight) {
      _errorMessage =
          'Weight must be between ${UserProfile.minWeight.toInt()} kg and ${UserProfile.maxWeight.toInt()} kg.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (height < UserProfile.minHeight || height > UserProfile.maxHeight) {
      _errorMessage =
          'Height must be between ${UserProfile.minHeight.toInt()} cm and ${UserProfile.maxHeight.toInt()} cm.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (age < UserProfile.minAge || age > UserProfile.maxAge) {
      _errorMessage =
          'Age must be between ${UserProfile.minAge} and ${UserProfile.maxAge}.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (targetWeight != null &&
        (targetWeight < UserProfile.minWeight ||
            targetWeight > UserProfile.maxWeight)) {
      _errorMessage =
          'Target weight must be between ${UserProfile.minWeight.toInt()} kg and ${UserProfile.maxWeight.toInt()} kg.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final now = DateTime.now();
    final newProfile = UserProfile(
      name: trimmedName,
      currentWeight: currentWeight,
      height: height,
      age: age,
      targetWeight: targetWeight,
      isOnboardingCompleted: true,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _storage.saveProfile(newProfile);
      _profile = newProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save profile. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update existing profile with validation
  Future<bool> updateProfile({
    String? name,
    double? currentWeight,
    double? height,
    int? age,
    double? targetWeight,
    bool clearTargetWeight = false,
  }) async {
    if (_profile == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final updatedName = (name ?? _profile!.name).trim();
    if (updatedName.isEmpty) {
      _errorMessage = 'Name cannot be empty.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final updatedWeight = currentWeight ?? _profile!.currentWeight;
    if (updatedWeight < UserProfile.minWeight ||
        updatedWeight > UserProfile.maxWeight) {
      _errorMessage =
          'Weight must be between ${UserProfile.minWeight.toInt()} kg and ${UserProfile.maxWeight.toInt()} kg.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final updatedHeight = height ?? _profile!.height;
    if (updatedHeight < UserProfile.minHeight ||
        updatedHeight > UserProfile.maxHeight) {
      _errorMessage =
          'Height must be between ${UserProfile.minHeight.toInt()} cm and ${UserProfile.maxHeight.toInt()} cm.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final updatedAge = age ?? _profile!.age;
    if (updatedAge < UserProfile.minAge || updatedAge > UserProfile.maxAge) {
      _errorMessage =
          'Age must be between ${UserProfile.minAge} and ${UserProfile.maxAge}.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final finalTargetWeight = clearTargetWeight
        ? null
        : (targetWeight ?? _profile!.targetWeight);

    if (finalTargetWeight != null &&
        (finalTargetWeight < UserProfile.minWeight ||
            finalTargetWeight > UserProfile.maxWeight)) {
      _errorMessage =
          'Target weight must be between ${UserProfile.minWeight.toInt()} kg and ${UserProfile.maxWeight.toInt()} kg.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final updatedProfile = _profile!.copyWith(
      name: updatedName,
      currentWeight: updatedWeight,
      height: updatedHeight,
      age: updatedAge,
      targetWeight: finalTargetWeight,
      clearTargetWeight: clearTargetWeight,
      updatedAt: DateTime.now(),
    );

    try {
      await _storage.saveProfile(updatedProfile);
      _profile = updatedProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset profile (for testing or user data reset)
  Future<void> resetProfile() async {
    _isLoading = true;
    notifyListeners();
    await _storage.clearProfile();
    _profile = null;
    _isLoading = false;
    notifyListeners();
  }
}
