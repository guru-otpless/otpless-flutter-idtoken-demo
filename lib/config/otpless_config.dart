import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads the OTPLESS App ID for the demo from `config/otpless_config.json`.
///
/// In your own app you can simply hard-code the App ID or read it from your
/// existing config system — the App ID is not a secret.
class OtplessConfig {
  const OtplessConfig({required this.appId});

  static const _assetPath = 'config/otpless_config.json';
  static const _placeholder = 'YOUR_APP_ID';

  final String appId;

  bool get isConfigured => appId.isNotEmpty && appId != _placeholder;

  static Future<OtplessConfig> load() async {
    try {
      final json = jsonDecode(await rootBundle.loadString(_assetPath));
      return OtplessConfig(appId: (json['appId'] as String? ?? '').trim());
    } catch (_) {
      // Missing or malformed config/otpless_config.json.
      return const OtplessConfig(appId: '');
    }
  }
}
