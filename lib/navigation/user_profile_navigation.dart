import 'package:flutter/material.dart';

import '../screens/search/other_user_profile_screen.dart';

void pushUserProfile(
  BuildContext context, {
  required int userId,
  required String username,
}) {
  if (userId <= 0) return;
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => OtherUserProfileScreen(userId: userId, usernameHint: username),
    ),
  );
}
