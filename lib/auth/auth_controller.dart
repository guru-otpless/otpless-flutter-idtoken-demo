import 'dart:async';

import 'package:flutter/foundation.dart';

import '../otpless/otpless_errors.dart';
import '../otpless/otpless_response.dart';
import '../otpless/otpless_service.dart';

/// Where the user is in the sign-in journey. The UI renders one page per step.
enum AuthStep {
  /// Enter phone / email or pick a social channel.
  enterIdentity,

  /// OTP was sent; user types it (or it is auto-read on Android).
  verifyOtp,

  /// Nothing to type: Silent Auth, magic link, or an OAuth app is in progress.
  waiting,

  /// ONETAP received. Send the token to your backend.
  authenticated,
}

sealed class AuthIdentity {
  const AuthIdentity();
  String get display;
}

class PhoneIdentity extends AuthIdentity {
  const PhoneIdentity({required this.countryCode, required this.number});
  final String countryCode;
  final String number;
  @override
  String get display => '+$countryCode $number';
}

class EmailIdentity extends AuthIdentity {
  const EmailIdentity(this.email);
  final String email;
  @override
  String get display => email;
}

class OAuthIdentity extends AuthIdentity {
  const OAuthIdentity(this.channelType);
  final String channelType;
  @override
  String get display => channelType;
}

/// Turns the stream of OTPLESS responses into simple UI state.
///
/// This is the piece to study when integrating: [_onResponse] shows how each
/// `responseType` should move your UI.
class AuthController extends ChangeNotifier {
  AuthController({OtplessService? service})
      : _service = service ?? OtplessService.instance {
    _subscription = _service.responses.listen(_onResponse);
  }

  final OtplessService _service;
  late final StreamSubscription<OtplessResponse> _subscription;

  AuthStep step = AuthStep.enterIdentity;
  AuthIdentity? identity;

  /// A request is in flight; disable buttons.
  bool busy = false;

  /// Last error to show, cleared on the next action.
  String? error;

  /// Neutral status line, e.g. "OTP sent via WHATSAPP".
  String? info;

  String? authType;
  String? deliveryChannel;

  /// Set when Android reads the OTP from SMS / WhatsApp.
  String? autoReadOtp;

  /// The ONETAP response once authenticated.
  OtplessResponse? result;

  // ---------------------------------------------------------------------------
  // Actions called by the UI
  // ---------------------------------------------------------------------------

  Future<void> startPhone({
    required String countryCode,
    required String number,
    String? deliveryChannel,
  }) {
    identity = PhoneIdentity(countryCode: countryCode, number: number);
    return _run(() => _service.startPhone(
          countryCode: countryCode,
          phone: number,
          deliveryChannel: deliveryChannel,
        ));
  }

  Future<void> startEmail(String email) {
    identity = EmailIdentity(email);
    return _run(() => _service.startEmail(email: email));
  }

  Future<void> startOAuth(String channelType) {
    identity = OAuthIdentity(channelType);
    return _run(() => _service.startOAuth(channelType));
  }

  Future<void> verifyOtp(String otp) {
    return switch (identity) {
      PhoneIdentity(:final countryCode, :final number) => _run(() =>
          _service.verifyPhoneOtp(
              countryCode: countryCode, phone: number, otp: otp)),
      EmailIdentity(:final email) =>
        _run(() => _service.verifyEmailOtp(email: email, otp: otp)),
      _ => Future.value(),
    };
  }

  /// Resending is just starting again with the same identity.
  Future<void> resendOtp() {
    autoReadOtp = null;
    return switch (identity) {
      PhoneIdentity(:final countryCode, :final number) =>
        startPhone(countryCode: countryCode, number: number),
      EmailIdentity(:final email) => startEmail(email),
      _ => Future.value(),
    };
  }

  /// Back to the first screen (also used for "Sign out" in the demo).
  void reset() {
    step = AuthStep.enterIdentity;
    identity = null;
    busy = false;
    error = null;
    info = null;
    authType = null;
    deliveryChannel = null;
    autoReadOtp = null;
    result = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() request) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      // The outcome arrives later through _onResponse.
      await request();
    } catch (e) {
      busy = false;
      error = e.toString();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // SDK responses → UI state
  // ---------------------------------------------------------------------------

  void _onResponse(OtplessResponse r) {
    switch (r.type) {
      case OtplessResponseType.initiate:
        if (r.isSuccess) {
          _applyInitiated(r);
        } else {
          _fail(OtplessErrors.messageFor(r));
        }

      case OtplessResponseType.fallbackTriggered:
        // SmartAuth moved to the next channel/method (e.g. SNA → SMS OTP).
        _applyInitiated(r);
        info = 'Resent via ${r.deliveryChannel ?? 'another channel'}';

      case OtplessResponseType.deliveryStatus:
        deliveryChannel = r.deliveryChannel ?? deliveryChannel;
        info = 'Delivered via ${deliveryChannel ?? 'your channel'}';

      case OtplessResponseType.otpAutoRead:
        // Android only. The OTP page fills the field and verifies.
        autoReadOtp = r.otp;

      case OtplessResponseType.verify:
        // VERIFY is only sent on failure; success comes as ONETAP.
        if (r.authType == OtplessAuthType.silentAuth) {
          if (r.statusCode == 9106) {
            // Silent Auth and every SmartAuth fallback failed.
            _fail(OtplessErrors.messageFor(r), restart: true);
          } else {
            // Wait: if SmartAuth is on, a new INITIATE with the next method
            // follows.
            info = 'Trying another way to verify you…';
          }
        } else {
          _fail(OtplessErrors.messageFor(r));
        }

      case OtplessResponseType.oneTap:
        // Success. r.token must be validated on YOUR backend.
        result = r;
        step = AuthStep.authenticated;
        busy = false;
        error = null;

      case OtplessResponseType.failed:
        _fail(OtplessErrors.messageFor(r), restart: true);

      case OtplessResponseType.authTerminated:
        _fail('Sign-in could not be completed. Please try another method.',
            restart: true);

      case OtplessResponseType.sdkReady:
      case OtplessResponseType.autoFlowAction:
      case OtplessResponseType.mfaFactorCompleted:
      case OtplessResponseType.unknown:
        return;
    }
    notifyListeners();
  }

  void _applyInitiated(OtplessResponse r) {
    authType = r.authType ?? authType;
    deliveryChannel = r.deliveryChannel ?? r.channel ?? deliveryChannel;
    final via = deliveryChannel != null ? ' via $deliveryChannel' : '';
    error = null;
    busy = false;

    if (identity is OAuthIdentity) {
      step = AuthStep.waiting;
      busy = true;
      info = 'Complete sign-in in ${identity!.display}…';
      return;
    }

    switch (authType) {
      case OtplessAuthType.otp:
        step = AuthStep.verifyOtp;
        info = 'OTP sent$via';
      case OtplessAuthType.otpLink:
        step = AuthStep.verifyOtp;
        info = 'OTP and sign-in link sent$via. Enter the OTP or tap the link.';
      case OtplessAuthType.magicLink:
        step = AuthStep.waiting;
        busy = true;
        info = 'Sign-in link sent$via. Open it on this device.';
      case OtplessAuthType.silentAuth:
        step = AuthStep.waiting;
        busy = true;
        info = 'Verifying your number with your mobile network…';
      default:
        step = AuthStep.waiting;
        busy = true;
        info = 'Waiting for verification…';
    }
  }

  void _fail(String message, {bool restart = false}) {
    busy = false;
    error = message;
    if (restart || step == AuthStep.waiting) step = AuthStep.enterIdentity;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
