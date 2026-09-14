import 'package:flutter/material.dart';

import '../models/loan.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;

  const LoanCard({
    super.key,
    required this.loan,
    required this.onOpen,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final editCallback = onEdit;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Выдача #${loan.id}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text('Читатель: ${loan.readerId}'),
                    Text('Книга: ${loan.bookId}'),
                    Text('Выдана: ${_date(loan.issuedAt)}'),
                    Text('Вернуть до: ${_date(loan.dueAt)}'),
                    Text('Статус: ${loan.status}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Открыть',
                          onPressed: onOpen,
                          icon: const Icon(Icons.open_in_new),
                        ),
                        if (editCallback != null)
                          IconButton(
                            tooltip: 'Редактировать',
                            onPressed: editCallback,
                            icon: const Icon(Icons.edit),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _date(DateTime value) {
    return value.toLocal().toString().split(' ').first;
  }
}
