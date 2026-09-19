import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../state/booking_list_notifier.dart';
import '../widgets/app_navigation_drawer.dart';

class BookingDetailScreen extends StatelessWidget {
  final String id;

  const BookingDetailScreen({
    super.key,
    required this.id,
  });

  Future<void> _deleteBooking(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить бронирование?'),
        content: const Text(
          'Бронирование будет отмечено как удалённое.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await context
          .read<BookingListNotifier>()
          .deleteBooking(id);

      if (!context.mounted) return;

      context.go('/bookings');
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    }
  }

  Future<void> _restoreBooking(BuildContext context) async {
    try {
      await context
          .read<BookingListNotifier>()
          .restoreItem(id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бронирование восстановлено'),
        ),
      );

      (context as Element).markNeedsBuild();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    }
  }

  Future<void> _hardDeleteBooking(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: const Text(
          'Бронирование будет удалено без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await context
          .read<BookingListNotifier>()
          .hardDeleteItem(id);

      if (!context.mounted) return;

      context.go('/bookings');
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<BookingListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бронирование'),
      ),
      drawer: const AppNavigationDrawer(
        currentRoute: '/bookings',
      ),
      body: FutureBuilder<Booking?>(
        future: notifier.findById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: ${snapshot.error}',
              ),
            );
          }

          final booking = snapshot.data;

          if (booking == null) {
            return const Center(
              child: Text('Бронирование не найдено'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Бронирование #${booking.id}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Редактировать',
                          onPressed: () {
                            context.go(
                              '/bookings/${booking.id}/edit',
                            );
                          },
                          icon: const Icon(Icons.edit),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _InfoRow(
                      label: 'ID',
                      value: booking.id,
                    ),
                    _InfoRow(
                      label: 'ID сеанса',
                      value: booking.sessionId,
                    ),
                    _InfoRow(
                      label: 'ID пользователя',
                      value: booking.userId,
                    ),
                    _InfoRow(
                      label: 'Ряд',
                      value: '${booking.row}',
                    ),
                    _InfoRow(
                      label: 'Место',
                      value: '${booking.seat}',
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            context.go(
                              '/bookings/${booking.id}/edit',
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Редактировать'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _deleteBooking(context),
                          icon: const Icon(Icons.delete),
                          label: const Text('Удалить'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _restoreBooking(context),
                          icon: const Icon(Icons.restore),
                          label: const Text('Восстановить'),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              _hardDeleteBooking(context),
                          icon: const Icon(
                            Icons.delete_forever,
                          ),
                          label: const Text(
                            'Удалить навсегда',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
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