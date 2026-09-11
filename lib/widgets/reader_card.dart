import 'package:flutter/material.dart';

import '../models/reader.dart';

class ReaderCard extends StatelessWidget {
  final Reader reader;
  final bool selected;
  final VoidCallback onSelectionChanged;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback? onRestore;
  final VoidCallback? onHardDelete;

  const ReaderCard({
    super.key,
    required this.reader,
    required this.selected,
    required this.onSelectionChanged,
    required this.onOpen,
    required this.onEdit,
    this.onRestore,
    this.onHardDelete,
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
                      reader.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(reader.email),
                    Text(reader.phone),
                    Text(
                      reader.card == null
                          ? 'Карты нет'
                          : 'Карта: ${reader.card!.number}',
                    ),
                    if (reader.isDeleted)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Удалён',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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
                        if (reader.isDeleted) ...[
                          IconButton(
                            tooltip: 'Восстановить',
                            onPressed: onRestore,
                            icon: const Icon(Icons.restore),
                          ),
                          IconButton(
                            tooltip: 'Удалить окончательно',
                            onPressed: onHardDelete,
                            icon: const Icon(Icons.delete_forever),
                          ),
                        ],
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
}
