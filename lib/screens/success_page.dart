import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth_controller.dart';

/// Step 3: ONETAP received. Shows only the idToken, with a copy button.
///
/// IMPORTANT: send the idToken to your backend and validate it with the
/// OTPLESS server-side API before creating a session. Never trust it on the
/// client alone.
class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idToken = controller.result?.idToken;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.verified_rounded, size: 72, color: Colors.green.shade600),
          const SizedBox(height: 16),
          Text('Verified',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(controller.identity?.display ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 32),
          if (idToken != null)
            _IdTokenField(idToken)
          else
            Text('No idToken was returned in the response.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 24),
          FilledButton.tonal(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: controller.reset,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _IdTokenField extends StatelessWidget {
  const _IdTokenField(this.idToken);

  final String idToken;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: idToken));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('idToken copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: idToken,
          readOnly: true,
          minLines: 3,
          maxLines: 8,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: const InputDecoration(labelText: 'idToken'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy),
          label: const Text('Copy idToken'),
        ),
      ],
    );
  }
}
