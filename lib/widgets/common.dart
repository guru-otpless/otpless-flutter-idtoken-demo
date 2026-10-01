import 'package:flutter/material.dart';

import '../otpless/otpless_service.dart';
import 'event_log_sheet.dart';

/// Red banner for SDK / validation errors.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: TextStyle(color: scheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}

/// Neutral status line, e.g. "OTP sent via WHATSAPP".
class InfoLine extends StatelessWidget {
  const InfoLine(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.info_outline, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    );
  }
}

/// Primary button that shows a spinner while [busy].
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(
              dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
          : Text(label),
    );
  }
}

/// App-bar chip showing whether SDK_READY has been received.
class SdkStatusChip extends StatelessWidget {
  const SdkStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OtplessService.instance.isReady,
      builder: (context, ready, _) {
        final color = ready ? Colors.green : Colors.orange;
        return Chip(
          visualDensity: VisualDensity.compact,
          avatar: Icon(Icons.circle, size: 10, color: color),
          label: Text(ready ? 'SDK ready' : 'Initializing'),
        );
      },
    );
  }
}

class EventLogButton extends StatelessWidget {
  const EventLogButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'SDK event log',
      icon: const Icon(Icons.receipt_long_outlined),
      onPressed: () => EventLogSheet.show(context),
    );
  }
}
