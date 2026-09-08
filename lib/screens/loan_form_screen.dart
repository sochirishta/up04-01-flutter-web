import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/loan.dart';
import '../models/reader.dart';
import '../repositories/book_repository.dart';
import '../repositories/loan_repository.dart';
import '../repositories/reader_repository.dart';
import '../models/book_query.dart';
import '../models/reader_query.dart';

class LoanFormScreen extends StatefulWidget {
  final int? id;

  const LoanFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<LoanFormScreen> createState() =>
      _LoanFormScreenState();
}

class _LoanFormScreenState
    extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Reader> _readers = [];
  List<Book> _books = [];

  int? _readerId;
  int? _bookId;

  DateTime _issuedAt = DateTime.now();

  DateTime _dueAt =
  DateTime.now().add(const Duration(days: 14));

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final readerRepository =
    context.read<ReaderRepository>();

    final bookRepository =
    context.read<BookRepository>();

    final loanRepository =
    context.read<LoanRepository>();

    final readerResult =
    await readerRepository.find(
      const ReaderQuery(size: 1000),
    );

    final bookResult =
    await bookRepository.find(
      const BookQuery(size: 1000),
    );

    Loan? loan;

    if (widget.isEditing) {
      loan = await loanRepository.findById(
        widget.id!,
      );
    }

    if (!mounted) return;

    _readers = readerResult.items;
    _books = bookResult.items;

    if (loan != null) {
      _readerId = loan.readerId;
      _bookId = loan.bookId;
      _issuedAt = loan.issuedAt;
      _dueAt = loan.dueAt;
    }

    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_readerId == null || _bookId == null) {
      return;
    }

    setState(() => _saving = true);

    final repository =
    context.read<LoanRepository>();

    try {
      if (widget.isEditing) {
        final old =
        await repository.findById(widget.id!);

        if (old == null) {
          throw StateError('Выдача не найдена');
        }

        await repository.update(
          old.copyWith(
            readerId: _readerId,
            bookId: _bookId,
            issuedAt: _issuedAt,
            dueAt: _dueAt,
          ),
        );
      } else {
        await repository.create(
          Loan(
            id: 0,
            readerId: _readerId!,
            bookId: _bookId!,
            issuedAt: _issuedAt,
            dueAt: _dueAt,
            status: 'active',
          ),
        );
      }

      if (!mounted) return;

      context.go('/loans');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Выдача'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Редактирование выдачи'
              : 'Новая выдача',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _readerId,
              decoration: const InputDecoration(
                labelText: 'Читатель',
                border: OutlineInputBorder(),
              ),
              items: _readers
                  .map(
                    (reader) => DropdownMenuItem(
                  value: reader.id,
                  child: Text(
                    '${reader.fullName} — ${reader.email}',
                  ),
                ),
              )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                setState(
                      () => _readerId = value,
                );
              },
              validator: (value) =>
              value == null
                  ? 'Выберите читателя'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _bookId,
              decoration: const InputDecoration(
                labelText: 'Книга',
                border: OutlineInputBorder(),
              ),
              items: _books
                  .map(
                    (book) => DropdownMenuItem(
                  value: book.id,
                  child: Text(
                    '${book.title} (${book.copiesAvailable})',
                  ),
                ),
              )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                setState(
                      () => _bookId = value,
                );
              },
              validator: (value) =>
              value == null
                  ? 'Выберите книгу'
                  : null,
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Дата выдачи'),
              subtitle: Text(
                _issuedAt
                    .toLocal()
                    .toString()
                    .split(' ')
                    .first,
              ),
            ),
            ListTile(
              title: const Text('Вернуть до'),
              subtitle: Text(
                _dueAt
                    .toLocal()
                    .toString()
                    .split(' ')
                    .first,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => context.go('/loans'),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed:
                  _saving ? null : _submit,
                  child: Text(
                    widget.isEditing
                        ? 'Сохранить'
                        : 'Создать',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}