import 'package:flutter/foundation.dart';

enum UserRole { patron, artist }

enum GenderOption { male, female, other, preferNotToSay }

class UserProfile {
  UserRole role;
  String username;
  String firstName;
  String lastName;
  String countryCode;
  String phoneNumber;
  DateTime? birthday;
  GenderOption gender;
  /// Server: URL or `data:image/...;base64,...`. Local-only until synced.
  String? avatarUrl;

  UserProfile({
    this.role = UserRole.patron,
    this.username = '',
    this.firstName = '',
    this.lastName = '',
    this.countryCode = '+63',
    this.phoneNumber = '',
    this.birthday,
    this.gender = GenderOption.male,
    this.avatarUrl,
  });
}

class AppProfileState extends ChangeNotifier {
  final UserProfile _profile = UserProfile();

  UserProfile get profile => _profile;

  void setRole(UserRole role) {
    _profile.role = role;
    notifyListeners();
  }

  void updateOnboardingInfo({
    required String username,
    required String firstName,
    required String lastName,
    required String countryCode,
    required String phoneNumber,
    required DateTime? birthday,
    required GenderOption gender,
  }) {
    _profile.username = username;
    _profile.firstName = firstName;
    _profile.lastName = lastName;
    _profile.countryCode = countryCode;
    _profile.phoneNumber = phoneNumber;
    _profile.birthday = birthday;
    _profile.gender = gender;
    notifyListeners();
  }

  void applyServerProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    if (username != null) _profile.username = username;
    if (firstName != null) _profile.firstName = firstName;
    if (lastName != null) _profile.lastName = lastName;
    if (clearAvatar) {
      _profile.avatarUrl = null;
    } else if (avatarUrl != null) {
      _profile.avatarUrl = avatarUrl;
    }
    notifyListeners();
  }
}

