import 'package:flutter/material.dart';

import '../models/reader.dart';

class ReaderCard extends StatelessWidget {
  final Reader reader;
  final bool selected;
  final VoidCallback? onSelectionChanged;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onRestore;
  final VoidCallback? onHardDelete;

  const ReaderCard({
    super.key,
    required this.reader,
    required this.selected,
    this.onSelectionChanged,
    required this.onOpen,
    this.onEdit,
    this.onRestore,
    this.onHardDelete,
  });

  @override
  Widget build(BuildContext context) {
    final selectionCallback = onSelectionChanged;
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
              if (selectionCallback != null) ...[
                Checkbox(
                  value: selected,
                  onChanged: (_) {
                    selectionCallback();
                  },
                ),
                const SizedBox(width: 8),
              ],
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
                    if (reader.isDeleted) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Удалён',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                        if (reader.isDeleted && onRestore != null)
                          IconButton(
                            tooltip: 'Восстановить',
                            onPressed: onRestore,
                            icon: const Icon(Icons.restore),
                          ),
                        if (reader.isDeleted && onHardDelete != null)
                          IconButton(
                            tooltip: 'Удалить окончательно',
                            onPressed: onHardDelete,
                            icon: const Icon(Icons.delete_forever),
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
}
