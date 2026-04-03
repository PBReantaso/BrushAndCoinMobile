import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'api_client.dart';

/// Called after login when push is wired up. Without [firebase_messaging] and
/// platform config there is no token — this is a no-op until you add them.
Future<void> trySyncPushDeviceAfterLogin(ApiClient api) async {
  const token = String.fromEnvironment('DEV_PUSH_TOKEN');
  if (token.isEmpty) {
    return;
  }
  final platform = kIsWeb
      ? 'web'
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          _ => 'web',
        };
  try {
    await api.registerPushDevice(token: token, platform: platform);
  } catch (_) {
    // Avoid surfacing registration errors during normal app use.
  }
}
