import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:otpless_headless_flutter/otpless_flutter.dart';

import 'otpless_response.dart';

/// Thin, app-wide wrapper around the OTPLESS Headless SDK.
///
/// Why a singleton: each `Otpless()` instance registers its own native
/// method-call handler, so creating several instances means only the last one
/// receives callbacks. Create exactly one and share it.
///
/// Responsibilities:
///  * initialize the SDK once,
///  * forward every SDK callback to [responses] (after `commitResponse`),
///  * build the request maps for phone / email / OAuth.
class OtplessService {
  OtplessService._();

  static final OtplessService instance = OtplessService._();

  final Otpless _otpless = Otpless();
  final StreamController<OtplessResponse> _responses =
      StreamController<OtplessResponse>.broadcast();

  /// Every SDK callback, in order.
  Stream<OtplessResponse> get responses => _responses.stream;

  /// Flips to true on SDK_READY.
  final ValueNotifier<bool> isReady = ValueNotifier(false);

  /// Redacted SDK traffic for the in-app event log. Demo only.
  final ValueNotifier<List<OtplessLogEntry>> log = ValueNotifier(const []);

  bool _initialized = false;

  /// Call once, as early as possible (e.g. before `runApp` or in the first
  /// screen's `initState`).
  Future<void> initialize(String appId, {bool devLogging = kDebugMode}) async {
    if (_initialized) return;
    _initialized = true;

    await _otpless.setDevLogging(devLogging);
    // Register the callback before initialize so SDK_READY / FAILED are not
    // missed.
    await _otpless.setResponseCallback(_onResponse);
    await _otpless.initialize(appId);
    _addLog('→ initialize', {'appId': appId});
  }

  // ---------------------------------------------------------------------------
  // Phone
  // ---------------------------------------------------------------------------

  /// Sends an OTP / magic link or starts Silent Auth, depending on the
  /// dashboard configuration.
  ///
  /// [countryCode] without "+", e.g. "91". [deliveryChannel] optionally forces
  /// "SMS" / "WHATSAPP" / "VIBER"; leave null to use the dashboard order.
  Future<void> startPhone({
    required String countryCode,
    required String phone,
    String? deliveryChannel,
  }) {
    return _start({
      'phone': phone,
      'countryCode': countryCode,
      'deliveryChannel': ?deliveryChannel,
    });
  }

  Future<void> verifyPhoneOtp({
    required String countryCode,
    required String phone,
    required String otp,
  }) {
    return _start({'phone': phone, 'countryCode': countryCode, 'otp': otp});
  }

  // ---------------------------------------------------------------------------
  // Email
  // ---------------------------------------------------------------------------

  Future<void> startEmail({required String email}) {
    return _start({'email': email});
  }

  Future<void> verifyEmailOtp({required String email, required String otp}) {
    return _start({'email': email, 'otp': otp});
  }

  // ---------------------------------------------------------------------------
  // OAuth / social
  // ---------------------------------------------------------------------------

  /// [channelType] e.g. "WHATSAPP", "GMAIL", "APPLE". The channel must be
  /// enabled in the OTPLESS dashboard.
  Future<void> startOAuth(String channelType) {
    return _start({'channelType': channelType});
  }

  // ---------------------------------------------------------------------------

  Future<void> _start(Map<String, dynamic> args) async {
    // Note: the iOS bridge reads every value as a String, so keep
    // countryCode / otp / otpLength / expiry as strings.
    if (!await _otpless.isSdkReady()) {
      throw const OtplessNotReadyException();
    }
    _addLog('→ start', args);
    await _otpless.start(_onResponse, args);
  }

  void _onResponse(dynamic raw) {
    // Acknowledge every response to the SDK first, as the docs require.
    _otpless.commitResponse(raw);

    final response = OtplessResponse.fromRaw(raw);
    _addLog('← ${response.rawType} (${response.statusCode})', response.raw);

    switch (response.type) {
      case OtplessResponseType.sdkReady:
        isReady.value = true;
      case OtplessResponseType.failed:
        isReady.value = false;
      default:
        break;
    }
    _responses.add(response);
  }

  void clearLog() => log.value = const [];

  void _addLog(String title, Map<String, dynamic> payload) {
    final entry = OtplessLogEntry(
      time: DateTime.now(),
      title: title,
      body: const JsonEncoder.withIndent('  ').convert(redact(payload)),
    );
    log.value = [entry, ...log.value].take(200).toList();
    debugPrint('[OTPLESS] $title');
  }

  static const _sensitiveKeys = {
    'otp',
    'token',
    'idtoken',
    'sessiontoken',
    'refreshtoken',
    'accesstoken',
    'code',
  };

  /// Replaces OTPs and tokens with "•••" so the log is safe to screenshot.
  static Object? redact(Object? value) {
    if (value is Map) {
      return value.map((key, v) => MapEntry(
            key.toString(),
            _sensitiveKeys.contains(key.toString().toLowerCase()) && v != null
                ? '•••'
                : redact(v),
          ));
    }
    if (value is List) return value.map(redact).toList();
    return value;
  }
}

class OtplessNotReadyException implements Exception {
  const OtplessNotReadyException();

  @override
  String toString() => 'Sign-in is still initializing. Please try again.';
}

class OtplessLogEntry {
  const OtplessLogEntry({
    required this.time,
    required this.title,
    required this.body,
  });

  final DateTime time;
  final String title;
  final String body;
}
