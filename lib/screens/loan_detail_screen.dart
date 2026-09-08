import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/loan_list_notifier.dart';

class LoanDetailScreen extends StatelessWidget {
  final int id;

  const LoanDetailScreen({
    super.key,
    required this.id,
  });

  Future<void> _returnLoan(
      BuildContext context,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вернуть книгу?'),
        content: const Text(
          'Книга будет отмечена как возвращённая.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Вернуть'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await context
          .read<LoanListNotifier>()
          .returnLoan(id);

      if (!context.mounted) return;

      context.go('/loans');
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
    final notifier = context.read<LoanListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выдача'),
      ),
      body: FutureBuilder(
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

          final loan = snapshot.data;

          if (loan == null) {
            return const Center(
              child: Text('Выдача не найдена'),
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
                            'Выдача #${loan.id}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Редактировать',
                          onPressed: () {
                            context.go(
                              '/loans/$id/edit',
                            );
                          },
                          icon: const Icon(
                            Icons.edit,
                          ),
                        ),
                        if (loan.returnedAt == null)
                          IconButton(
                            tooltip: 'Вернуть книгу',
                            onPressed: () =>
                                _returnLoan(context),
                            icon: const Icon(
                              Icons.assignment_return,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _InfoRow(
                      label: 'ID',
                      value: '${loan.id}',
                    ),
                    _InfoRow(
                      label: 'ID читателя',
                      value: '${loan.readerId}',
                    ),
                    _InfoRow(
                      label: 'ID книги',
                      value: '${loan.bookId}',
                    ),
                    _InfoRow(
                      label: 'Дата выдачи',
                      value: _date(loan.issuedAt),
                    ),
                    _InfoRow(
                      label: 'Вернуть до',
                      value: _date(loan.dueAt),
                    ),
                    _InfoRow(
                      label: 'Дата возврата',
                      value: loan.returnedAt == null
                          ? 'Не возвращена'
                          : _date(
                        loan.returnedAt!,
                      ),
                    ),
                    _InfoRow(
                      label: 'Статус',
                      value: loan.status,
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

  static String _date(DateTime value) {
    return value
        .toLocal()
        .toString()
        .split(' ')
        .first;
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
            child: Text(value),
          ),
        ],
      ),
    );
  }
}