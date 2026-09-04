import 'package:flutter/material.dart';

import '../models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final bool selected;
  final VoidCallback onSelectionChanged;
  final VoidCallback onOpen;
  final VoidCallback? onRestore;
  final VoidCallback? onHardDelete;

  const BookCard({
    super.key,
    required this.book,
    required this.selected,
    required this.onSelectionChanged,
    required this.onOpen,
    this.onRestore,
    this.onHardDelete,
  });

  @override
  Widget build(BuildContext context) {
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
              Checkbox(
                value: selected,
                onChanged: (_) {
                  onSelectionChanged();
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text('ISBN: ${book.isbn}'),
                    Text('Год: ${book.year}'),
                    Text('Страницы: ${book.pages}'),
                    Text(
                      'Экземпляры: '
                          '${book.copiesAvailable}/'
                          '${book.copiesTotal}',
                    ),

                    if (book.isDeleted) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Удалена',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .error,
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
                          icon: const Icon(
                            Icons.open_in_new,
                          ),
                        ),

                        if (book.isDeleted) ...[
                          IconButton(
                            tooltip: 'Восстановить',
                            onPressed: onRestore,
                            icon: const Icon(
                              Icons.restore,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Удалить окончательно',
                            onPressed: onHardDelete,
                            icon: const Icon(
                              Icons.delete_forever,
                            ),
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