import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../state/book_list_notifier.dart';

class BookDetailScreen extends StatelessWidget {
  final int id;

  const BookDetailScreen({
    super.key,
    required this.id,
  });

  Future<void> _deleteBook(
      BuildContext context,
      Book book,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: Text(
          'Вы действительно хотите удалить книгу '
              '«${book.title}»?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<BookListNotifier>().deleteBook(book.id);

    if (!context.mounted) return;

    context.go('/books');
  }

  Future<void> _restoreBook(
      BuildContext context,
      Book book,
      ) async {
    await context.read<BookListNotifier>().restoreItem(book.id);

    if (!context.mounted) return;

    context.go('/books');
  }

  Future<void> _hardDeleteBook(
      BuildContext context,
      Book book,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книгу окончательно?'),
        content: Text(
          'Книга «${book.title}» будет удалена без возможности '
              'восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Удалить окончательно'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context
        .read<BookListNotifier>()
        .hardDeleteItem(book.id);

    if (!context.mounted) return;

    context.go('/books');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Книга'),
        actions: [
          IconButton(
            tooltip: 'Редактировать',
            onPressed: () {
              context.go('/books/$id/edit');
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: FutureBuilder<Book?>(
        future: context.read<BookRepository>().findById(id),
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

          final book = snapshot.data;

          if (book == null) {
            return const Center(
              child: Text('Книга не найдена'),
            );
          }

          return _BookCard(
            book: book,
            onEdit: () {
              context.go('/books/${book.id}/edit');
            },
            onDelete: () {
              _deleteBook(context, book);
            },
            onRestore: () {
              _restoreBook(context, book);
            },
            onHardDelete: () {
              _hardDeleteBook(context, book);
            },
          );
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onHardDelete;

  const _BookCard({
    required this.book,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
    required this.onHardDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      book.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Редактировать',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                      ),
                      if (!book.isDeleted)
                        IconButton(
                          tooltip: 'Удалить',
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete),
                        ),
                      if (book.isDeleted)
                        IconButton(
                          tooltip: 'Восстановить',
                          onPressed: onRestore,
                          icon: const Icon(Icons.restore),
                        ),
                      if (book.isDeleted)
                        IconButton(
                          tooltip: 'Удалить окончательно',
                          onPressed: onHardDelete,
                          icon: const Icon(
                            Icons.delete_forever,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _InfoRow(
                label: 'ISBN',
                value: book.isbn,
              ),
              _InfoRow(
                label: 'Год издания',
                value: '${book.year}',
              ),
              _InfoRow(
                label: 'Количество страниц',
                value: '${book.pages}',
              ),
              _InfoRow(
                label: 'Издатель',
                value: '${book.publisherId}',
              ),
              _InfoRow(
                label: 'Всего экземпляров',
                value: '${book.copiesTotal}',
              ),
              _InfoRow(
                label: 'Доступно',
                value: '${book.copiesAvailable}',
              ),
              _InfoRow(
                label: 'ID авторов',
                value: book.authorIds.join(', '),
              ),
              _InfoRow(
                label: 'ID жанров',
                value: book.genreIds.join(', '),
              ),

              if (book.isDeleted)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Книга удалена',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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