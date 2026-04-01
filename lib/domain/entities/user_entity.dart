/// Pure Dart domain entity representing the essential user facts
/// needed across use cases. Has no framework or package dependencies.
class UserEntity {
  final String id;
  final String username;

  /// Age group: 1 = ages 8–10, 2 = ages 11–14, 3 = ages 15–18.
  final int ageGroup;

  final int currentLevel;
  final int currentStreak;

  const UserEntity({
    required this.id,
    required this.username,
    required this.ageGroup,
    required this.currentLevel,
    required this.currentStreak,
  });

  /// Approximate minimum age for this user based on their age group.
  int get approximateMinAge {
    switch (ageGroup) {
      case 1:
        return 8;
      case 2:
        return 11;
      case 3:
        return 15;
      default:
        return 8;
    }
  }

  /// True when the user is under 13 and parental consent is required.
  bool get requiresParentalConsent => approximateMinAge < 13;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserEntity(id: $id, username: $username, ageGroup: $ageGroup, '
      'currentLevel: $currentLevel, currentStreak: $currentStreak)';
}
