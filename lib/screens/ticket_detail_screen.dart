import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/ticket.dart';
import '../state/ticket_list_notifier.dart';
import '../widgets/app_navigation_drawer.dart';

class TicketDetailScreen extends StatefulWidget {
  final String id;

  const TicketDetailScreen({
    super.key,
    required this.id,
  });

  @override
  State<TicketDetailScreen> createState() =>
      _TicketDetailScreenState();
}

class _TicketDetailScreenState
    extends State<TicketDetailScreen> {
  Ticket? _ticket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    final notifier = context.read<TicketListNotifier>();
    final ticket = await notifier.findById(widget.id);

    if (!mounted) return;

    setState(() {
      _ticket = ticket;
      _isLoading = false;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить билет?'),
        content: const Text(
          'Билет будет перемещён в удалённые.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await context
        .read<TicketListNotifier>()
        .deleteTicket(widget.id);

    if (mounted) {
      context.go('/tickets');
    }
  }

  Future<void> _restore() async {
    await context
        .read<TicketListNotifier>()
        .restoreItem(widget.id);

    await _load();
  }

  Future<void> _hardDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить билет навсегда?'),
        content: const Text(
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await context
        .read<TicketListNotifier>()
        .hardDeleteItem(widget.id);

    if (mounted) {
      context.go('/tickets');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Билет'),
        actions: [
          if (_ticket != null)
            IconButton(
              tooltip: 'Изменить',
              onPressed: () {
                context.go('/tickets/${widget.id}/edit');
              },
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      drawer: const AppNavigationDrawer(
        currentRoute: '/tickets',
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _ticket == null
          ? const Center(
        child: Text('Билет не найден'),
      )
          : _TicketCard(
        ticket: _ticket!,
        onDelete: _delete,
        onRestore: _restore,
        onHardDelete: _hardDelete,
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onHardDelete;

  const _TicketCard({
    required this.ticket,
    required this.onDelete,
    required this.onRestore,
    required this.onHardDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Билет',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 20),
                _InfoRow(
                  label: 'ID',
                  value: ticket.id,
                ),
                _InfoRow(
                  label: 'Booking ID',
                  value: ticket.bookingId,
                ),
                _InfoRow(
                  label: 'Номер',
                  value: ticket.number,
                ),
                _InfoRow(
                  label: 'Выдан',
                  value: _formatDateTime(ticket.issuedAt),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        context.go(
                          '/tickets/${ticket.id}/edit',
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Изменить'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('Удалить'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onRestore,
                      icon: const Icon(Icons.restore),
                      label: const Text('Восстановить'),
                    ),
                    TextButton.icon(
                      onPressed: onHardDelete,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Удалить навсегда'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
}