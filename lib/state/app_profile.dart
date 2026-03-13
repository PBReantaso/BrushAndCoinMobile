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

  UserProfile({
    this.role = UserRole.patron,
    this.username = '',
    this.firstName = '',
    this.lastName = '',
    this.countryCode = '+63',
    this.phoneNumber = '',
    this.birthday,
    this.gender = GenderOption.male,
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
}

