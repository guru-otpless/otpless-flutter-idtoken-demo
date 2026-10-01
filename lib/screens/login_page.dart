import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth_controller.dart';
import '../widgets/common.dart';

enum _Method { phone, email, social }

/// Step 1: collect phone / email, or pick a social channel.
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
  final _email = TextEditingController();

  _Method _method = _Method.phone;

  /// null = let the dashboard decide (recommended).
  String? _deliveryChannel;

  @override
  void dispose() {
    _countryCode.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final c = widget.controller;
    switch (_method) {
      case _Method.phone:
        c.startPhone(
          countryCode: _countryCode.text.trim(),
          number: _phone.text.trim(),
          deliveryChannel: _deliveryChannel,
        );
      case _Method.email:
        c.startEmail(_email.text.trim());
      case _Method.social:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sign in', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Powered by the OTPLESS Headless SDK',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            SegmentedButton<_Method>(
              segments: const [
                ButtonSegment(
                    value: _Method.phone,
                    icon: Icon(Icons.phone_iphone),
                    label: Text('Phone')),
                ButtonSegment(
                    value: _Method.email,
                    icon: Icon(Icons.alternate_email),
                    label: Text('Email')),
                ButtonSegment(
                    value: _Method.social,
                    icon: Icon(Icons.apps),
                    label: Text('Social')),
              ],
              selected: {_method},
              onSelectionChanged:
                  c.busy ? null : (s) => setState(() => _method = s.first),
            ),
            const SizedBox(height: 24),
            if (c.error != null) ...[
              ErrorBanner(c.error!),
              const SizedBox(height: 16),
            ],
            ...switch (_method) {
              _Method.phone => _phoneFields(),
              _Method.email => _emailFields(),
              _Method.social => [_SocialGrid(controller: c)],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _phoneFields() {
    final busy = widget.controller.busy;
    return [
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
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: const InputDecoration(labelText: 'Phone number'),
              validator: (v) => (v == null || v.trim().length < 6)
                  ? 'Enter a valid number'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String?>(
        initialValue: _deliveryChannel,
        decoration: const InputDecoration(labelText: 'Delivery channel'),
        items: const [
          DropdownMenuItem(value: null, child: Text('Auto (dashboard config)')),
          DropdownMenuItem(value: 'SMS', child: Text('SMS')),
          DropdownMenuItem(value: 'WHATSAPP', child: Text('WhatsApp')),
        ],
        onChanged: busy ? null : (v) => setState(() => _deliveryChannel = v),
      ),
      const SizedBox(height: 24),
      BusyButton(label: 'Continue', busy: busy, onPressed: _submit),
    ];
  }

  List<Widget> _emailFields() {
    final busy = widget.controller.busy;
    return [
      TextFormField(
        controller: _email,
        enabled: !busy,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(labelText: 'Email address'),
        validator: (v) {
          final value = v?.trim() ?? '';
          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
              ? null
              : 'Enter a valid email';
        },
        onFieldSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: 24),
      BusyButton(label: 'Continue', busy: busy, onPressed: _submit),
    ];
  }
}

class _SocialGrid extends StatelessWidget {
  const _SocialGrid({required this.controller});

  final AuthController controller;

  /// Channel names accepted by `start({'channelType': ...})`. Each must be
  /// enabled in the OTPLESS dashboard.
  static const _channels = [
    ('WHATSAPP', 'WhatsApp', Color(0xFF25D366)),
    ('GMAIL', 'Google', Color(0xFFEA4335)),
    ('APPLE', 'Apple', Color(0xFF000000)),
    ('MICROSOFT', 'Microsoft', Color(0xFF0078D4)),
    ('FACEBOOK', 'Facebook', Color(0xFF1877F2)),
    ('LINKEDIN', 'LinkedIn', Color(0xFF0A66C2)),
    ('GITHUB', 'GitHub', Color(0xFF24292F)),
    ('TWITTER', 'X / Twitter', Color(0xFF14171A)),
    ('SLACK', 'Slack', Color(0xFF4A154B)),
    ('DISCORD', 'Discord', Color(0xFF5865F2)),
  ];

  @override
  Widget build(BuildContext context) {
    final channels = _channels
        // Sign in with Apple is typically only offered on iOS.
        .where((c) => c.$1 != 'APPLE' || Platform.isIOS)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Only channels enabled in your OTPLESS dashboard will work.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (final (channel, label, color) in channels) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
            onPressed:
                controller.busy ? null : () => controller.startOAuth(channel),
            icon: CircleAvatar(
              radius: 12,
              backgroundColor: color,
              child: Text(label[0],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            label: Text('Continue with $label'),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
