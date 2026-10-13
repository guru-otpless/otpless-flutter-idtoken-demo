import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth_controller.dart';
import '../widgets/common.dart';

/// Step 2: enter the OTP. On Android the SDK may read it automatically
/// (OTP_AUTO_READ), in which case we fill the field and verify right away.
class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  static const _otpLength = 6;
  static const _resendAfter = Duration(seconds: 30);

  final _otp = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 0;
  String? _handledAutoReadOtp;

  AuthController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onControllerChanged);
    _startCooldown();
  }

  @override
  void dispose() {
    _c.removeListener(_onControllerChanged);
    _timer?.cancel();
    _otp.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final otp = _c.autoReadOtp;
    if (otp != null && otp != _handledAutoReadOtp) {
      _handledAutoReadOtp = otp;
      final digits = otp.replaceAll(RegExp(r'\D'), '');
      _otp.text = digits.length > _otpLength
          ? digits.substring(0, _otpLength)
          : digits;
      // Defer so we don't start a request from inside notifyListeners.
      scheduleMicrotask(_verify);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    _secondsLeft = _resendAfter.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft--);
    });
  }

  void _verify() {
    if (!mounted) return;
    final otp = _otp.text.trim();
    if (otp.length != _otpLength) return;
    FocusScope.of(context).unfocus();
    _c.verifyOtp(otp);
  }

  void _resend() {
    _otp.clear();
    _c.resendOtp();
    setState(_startCooldown);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Enter OTP', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Sent to '),
                TextSpan(
                  text: _c.identity?.display ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_c.error != null) ...[
            ErrorBanner(_c.error!),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _otp,
            autofocus: true,
            enabled: !_c.busy,
            keyboardType: TextInputType.number,
            // Lets iOS offer the OTP from Messages above the keyboard.
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              // Enforced: on Android the default lets extra digits through
              // while the keyboard is composing.
              LengthLimitingTextInputFormatter(
                _otpLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
              ),
            ],
            maxLength: _otpLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 12),
            decoration: const InputDecoration(
              hintText: '••••••',
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 12),
          if (_c.info != null) InfoLine(_c.info!),
          const SizedBox(height: 24),
          BusyButton(
            label: 'Verify',
            busy: _c.busy,
            onPressed: _otp.text.length == _otpLength ? _verify : null,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _secondsLeft > 0 || _c.busy ? null : _resend,
            child: Text(
              _secondsLeft > 0
                  ? 'Resend OTP in ${_secondsLeft}s'
                  : 'Resend OTP',
            ),
          ),
          TextButton(
            onPressed: _c.reset,
            child: Text(
              'Change ${_c.identity is EmailIdentity ? 'email' : 'number'}',
            ),
          ),
        ],
      ),
    );
  }
}
