import 'package:flutter/material.dart';

import '../models/loan.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final bool selected;
  final VoidCallback onSelectionChanged;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const LoanCard({
    super.key,
    required this.loan,
    required this.selected,
    required this.onSelectionChanged,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: selected, onChanged: (_) => onSelectionChanged()),
              const SizedBox(width: 8),
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
                    Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Открыть',
                          onPressed: onOpen,
                          icon: const Icon(Icons.open_in_new),
                        ),
                        IconButton(
                          tooltip: 'Редактировать',
                          onPressed: onEdit,
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
