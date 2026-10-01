import 'package:flutter/material.dart';

/// Shown when config/otpless_config.json is missing or still has the
/// placeholder App ID.
class SetupRequiredPage extends StatelessWidget {
  const SetupRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    return Scaffold(
      appBar: AppBar(title: const Text('OTPLESS Demo')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.settings_suggest_outlined,
              size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Add your OTPLESS App ID',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('1. Copy your App ID from the OTPLESS dashboard.'),
          const SizedBox(height: 8),
          const Text('2. From the project root run:'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.surfaceContainerHighest,
            child: SelectableText('./scripts/configure.sh YOUR_APP_ID',
                style: mono),
          ),
          const SizedBox(height: 8),
          const Text(
              '3. Stop the app and run it again (a hot reload does not pick up '
              'new assets or native config).'),
          const SizedBox(height: 16),
          const Text(
              'See README.md for what the script changes on Android and iOS.'),
        ],
      ),
    );
  }
}
