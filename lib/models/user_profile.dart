class UserProfile {
  static const String defaultProfileId = 'user_profile_primary';

  // Reasonable human validation bounds
  static const double minWeight = 20.0;
  static const double maxWeight = 400.0;
  static const double minHeight = 50.0;
  static const double maxHeight = 300.0;
  static const int minAge = 10;
  static const int maxAge = 120;

  final String id;
  final String name;
  final double currentWeight; // in kg
  final double height; // in cm
  final int age;
  final double? targetWeight; // in kg (optional)
  final String? avatarPath;
  final bool isOnboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    this.id = defaultProfileId,
    required this.name,
    required this.currentWeight,
    required this.height,
    required this.age,
    this.targetWeight,
    this.avatarPath,
    this.isOnboardingCompleted = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Extracts user initials for avatar (e.g. "Alex Mercer" -> "AM", "Alex" -> "A")
  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'V';

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    final first = parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
    final last = parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
    final combined = '$first$last';
    return combined.isNotEmpty ? combined : 'V';
  }

  UserProfile copyWith({
    String? id,
    String? name,
    double? currentWeight,
    double? height,
    int? age,
    double? targetWeight,
    bool clearTargetWeight = false,
    String? avatarPath,
    bool? isOnboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      currentWeight: currentWeight ?? this.currentWeight,
      height: height ?? this.height,
      age: age ?? this.age,
      targetWeight: clearTargetWeight
          ? null
          : (targetWeight ?? this.targetWeight),
      avatarPath: avatarPath ?? this.avatarPath,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currentWeight': currentWeight,
      'height': height,
      'age': age,
      'targetWeight': targetWeight,
      'avatarPath': avatarPath,
      'isOnboardingCompleted': isOnboardingCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? defaultProfileId,
      name: json['name'] as String? ?? '',
      currentWeight: (json['currentWeight'] as num?)?.toDouble() ?? 70.0,
      height: (json['height'] as num?)?.toDouble() ?? 175.0,
      age: (json['age'] as num?)?.toInt() ?? 25,
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      avatarPath: json['avatarPath'] as String?,
      isOnboardingCompleted: json['isOnboardingCompleted'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
