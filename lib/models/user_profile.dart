class UserProfile {
  final String name;
  final String gender;
  final int age;
  final double? heightCm;
  final String heardFrom;
  final String installReason;
  final List<String> focusAreas;
  final String skincareFrequency;
  final String exerciseFrequency;
  final bool onboardingDone;

  const UserProfile({
    required this.name,
    required this.gender,
    required this.age,
    this.heightCm,
    required this.heardFrom,
    required this.installReason,
    required this.focusAreas,
    required this.skincareFrequency,
    required this.exerciseFrequency,
    this.onboardingDone = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'age': age,
        'heightCm': heightCm,
        'heardFrom': heardFrom,
        'installReason': installReason,
        'focusAreas': focusAreas,
        'skincareFrequency': skincareFrequency,
        'exerciseFrequency': exerciseFrequency,
        'onboardingDone': onboardingDone,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? '',
        gender: json['gender'] as String? ?? '',
        age: json['age'] as int? ?? 18,
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        heardFrom: json['heardFrom'] as String? ?? '',
        installReason: json['installReason'] as String? ?? '',
        focusAreas: (json['focusAreas'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        skincareFrequency: json['skincareFrequency'] as String? ?? '',
        exerciseFrequency: json['exerciseFrequency'] as String? ?? '',
        onboardingDone: json['onboardingDone'] as bool? ?? true,
      );
}
