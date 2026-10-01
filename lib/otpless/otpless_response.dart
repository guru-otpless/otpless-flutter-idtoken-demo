/// Typed view over the raw map the OTPLESS SDK delivers to the response
/// callback.
///
/// Every callback has the shape:
/// ```json
/// { "responseType": "INITIATE", "statusCode": 200, "response": { ... } }
/// ```
library;

enum OtplessResponseType {
  /// SDK finished initializing. `start()` can be called from now on.
  sdkReady('SDK_READY'),

  /// Terminal SDK-level failure (e.g. 5003 init failed, 5004 SSL pinning).
  failed('FAILED'),

  /// Result of starting authentication. `statusCode == 200` means the OTP /
  /// magic link was sent or Silent Auth started; anything else is an error.
  initiate('INITIATE'),

  /// Android only: OTP read automatically from SMS / WhatsApp.
  otpAutoRead('OTP_AUTO_READ'),

  /// Verification failed (wrong OTP, expired, Silent Auth failed, ...).
  /// Successful verification arrives as [oneTap], not as [verify].
  verify('VERIFY'),

  /// OTP / link was delivered on a channel.
  deliveryStatus('DELIVERY_STATUS'),

  /// Authentication succeeded. Contains the token to verify on your backend.
  oneTap('ONETAP'),

  /// Delivery on the primary channel failed and SmartAuth retried on the next
  /// channel configured in the dashboard.
  fallbackTriggered('FALLBACK_TRIGGERED'),

  /// Authentication ended without success (e.g. SNA-only config failed).
  authTerminated('AUTH_TERMINATED'),

  /// Android only: OneTap / auto-flow dialog actions.
  autoFlowAction('AUTO_FLOW_ACTION'),

  /// A factor completed while MFA is enabled.
  mfaFactorCompleted('MFA_FACTOR_COMPLETED'),

  unknown('UNKNOWN');

  const OtplessResponseType(this.wireName);

  final String wireName;

  static OtplessResponseType parse(Object? value) {
    for (final type in values) {
      if (type.wireName == value) return type;
    }
    return unknown;
  }
}

/// Auth types reported in `response.authType`.
abstract final class OtplessAuthType {
  static const otp = 'OTP';
  static const magicLink = 'MAGICLINK';
  static const otpLink = 'OTP_LINK';
  static const silentAuth = 'SILENT_AUTH';
}

class OtplessResponse {
  OtplessResponse._({
    required this.type,
    required this.rawType,
    required this.statusCode,
    required this.response,
    required this.raw,
  });

  factory OtplessResponse.fromRaw(dynamic raw) {
    final map = _asMap(raw);
    return OtplessResponse._(
      type: OtplessResponseType.parse(map['responseType']),
      rawType: map['responseType']?.toString() ?? 'UNKNOWN',
      // statusCode is an int on both platforms today; parse defensively.
      statusCode: int.tryParse(map['statusCode']?.toString() ?? '') ?? -1,
      response: _asMap(map['response']),
      raw: map,
    );
  }

  final OtplessResponseType type;
  final String rawType;
  final int statusCode;
  final Map<String, dynamic> response;

  /// The untouched callback payload. Pass this (not [response]) to
  /// `Otpless.commitResponse`.
  final Map<String, dynamic> raw;

  bool get isSuccess => statusCode == 200;

  String? get authType => _string(response['authType']);
  String? get deliveryChannel => _string(response['deliveryChannel']);
  String? get channel => _string(response['channel']);
  String? get requestId => _string(response['requestId']);
  String? get otp => _string(response['otp']);
  String? get errorCode => _string(response['errorCode']);
  String? get errorMessage => _string(response['errorMessage']);

  /// ONETAP: `response.token`, or `response.data.token` depending on the flow.
  String? get token =>
      _string(response['token']) ?? _string(_asMap(response['data'])['token']);

  /// ONETAP: OpenID id token when available.
  String? get idToken =>
      _string(response['idToken']) ??
      _string(_asMap(response['data'])['idToken']);

  @override
  String toString() => 'OtplessResponse($rawType, $statusCode)';

  static String? _string(Object? value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
