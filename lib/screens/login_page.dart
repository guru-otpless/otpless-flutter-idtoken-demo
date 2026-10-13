import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth_controller.dart';
import '../widgets/common.dart';

/// Step 1: collect the phone number. The dashboard config decides the flow
/// (Silent Network Auth first, with OTP fallback if SmartAuth is on).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _countryCode = TextEditingController(text: '91');
  final _phone = TextEditingController();

  @override
  void dispose() {
    _countryCode.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.controller.startPhone(
      countryCode: _countryCode.text.trim(),
      number: _phone.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final busy = c.busy;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Verify your number', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Use mobile data (Wi-Fi off) for Silent Network Auth',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            if (c.error != null) ...[
              ErrorBanner(c.error!),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: TextFormField(
                    controller: _countryCode,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                        labelText: 'Code', prefixText: '+'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phone,
                    enabled: !busy,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [
                      AutofillHints.telephoneNumberNational
                    ],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                    decoration:
                        const InputDecoration(labelText: 'Phone number'),
                    validator: (v) => (v == null || v.trim().length < 6)
                        ? 'Enter a valid number'
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            BusyButton(label: 'Continue', busy: busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
