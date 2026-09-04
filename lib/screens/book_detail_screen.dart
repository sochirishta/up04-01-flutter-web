import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../repositories/book_repository.dart';

class BookDetailScreen extends StatelessWidget {
  final int id;

  const BookDetailScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Книга'),
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

          return _BookCard(book: book);
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;

  const _BookCard({
    required this.book,
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
              Text(
                book.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
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