import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth_controller.dart';
import '../otpless/otpless_service.dart';

/// Step 3: ONETAP received.
///
/// IMPORTANT: the token is only proof that the user *claims* to be verified.
/// Send it to your backend and validate it with the OTPLESS server-side API
/// before creating a session. Never trust it on the client alone.
class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  bool _reveal = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.controller.result;
    final token = result?.token;
    final idToken = result?.idToken;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.verified_rounded, size: 72, color: Colors.green.shade600),
          const SizedBox(height: 16),
          Text('Signed in',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(widget.controller.identity?.display ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Next step in your app: send the token below to your backend '
                'and verify it with the OTPLESS server-side token validation '
                'API. Create the user session only after that succeeds.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (token != null)
            _TokenTile(label: 'token', value: token, reveal: _reveal),
          if (idToken != null)
            _TokenTile(label: 'idToken', value: idToken, reveal: _reveal),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show tokens'),
            value: _reveal,
            onChanged: (v) => setState(() => _reveal = v),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('ONETAP response (redacted)'),
            children: [
              SelectableText(
                const JsonEncoder.withIndent('  ')
                    .convert(OtplessService.redact(result?.raw ?? {})),
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: widget.controller.reset,
            child: const Text('Sign out & try again'),
          ),
        ],
      ),
    );
  }
}

class _TokenTile extends StatelessWidget {
  const _TokenTile({
    required this.label,
    required this.value,
    required this.reveal,
  });

  final String label;
  final String value;
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    final shown = reveal
        ? value
        : '${value.substring(0, value.length.clamp(0, 6))}••••••••';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(shown,
          maxLines: reveal ? null : 1,
          style: const TextStyle(fontFamily: 'monospace')),
      trailing: IconButton(
        tooltip: 'Copy',
        icon: const Icon(Icons.copy),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$label copied')));
        },
      ),
    );
  }
}
