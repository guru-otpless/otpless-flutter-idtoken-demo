import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../otpless/otpless_service.dart';

/// Bottom sheet listing every request sent to and response received from the
/// SDK, with OTPs and tokens redacted. Useful while integrating; remove it
/// from production apps.
class EventLogSheet extends StatelessWidget {
  const EventLogSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.8,
        child: EventLogSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = OtplessService.instance;
    return ValueListenableBuilder<List<OtplessLogEntry>>(
      valueListenable: service.log,
      builder: (context, entries, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('SDK event log',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  IconButton(
                    tooltip: 'Copy all',
                    icon: const Icon(Icons.copy_all_outlined),
                    onPressed: entries.isEmpty
                        ? null
                        : () => _copy(context, entries),
                  ),
                  IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: entries.isEmpty ? null : service.clearLog,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('No events yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _EntryTile(entries[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _copy(BuildContext context, List<OtplessLogEntry> entries) {
    final text = entries
        .map((e) => '${e.time.toIso8601String()} ${e.title}\n${e.body}')
        .join('\n\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Log copied')));
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile(this.entry);

  final OtplessLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = entry.time;
    final time = '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$time  ${entry.title}', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          SelectableText(
            entry.body,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontFamily: 'monospace', height: 1.4),
          ),
        ],
      ),
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
