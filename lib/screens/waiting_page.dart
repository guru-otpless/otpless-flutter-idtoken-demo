import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../widgets/common.dart';

/// Shown while there is nothing for the user to type: Silent Network Auth,
/// a magic link, or an OAuth app (WhatsApp, Google, ...) is in progress.
/// The SDK sends ONETAP on success, or VERIFY / FALLBACK_TRIGGERED otherwise.
class WaitingPage extends StatelessWidget {
  const WaitingPage({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
                dimension: 56,
                child: CircularProgressIndicator(strokeWidth: 4)),
            const SizedBox(height: 32),
            Text(controller.identity?.display ?? '',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (controller.info != null)
              Text(controller.info!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge),
            if (controller.error != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(controller.error!),
            ],
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: controller.reset,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
