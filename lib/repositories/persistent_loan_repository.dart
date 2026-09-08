import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/loan.dart';
import '../models/loan_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';
import 'loan_repository.dart';
import 'reader_repository.dart';

class PersistentLoanRepository implements LoanRepository {
  static const _key = 'loans_v1';

  final SharedPreferences _prefs;
  final BookRepository _bookRepository;
  final ReaderRepository _readerRepository;

  List<Loan> _loans = [];
  int _nextId = 1;

  PersistentLoanRepository(
      this._prefs,
      this._bookRepository,
      this._readerRepository,
      ) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);

    if (raw == null) {
      _loans = [...seedLoans];
      _recalculateNextId();
      _persist();
      return;
    }

    try {
      final list = jsonDecode(raw) as List;

      _loans = list
          .map(
            (e) => Loan.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .toList();

      _recalculateNextId();
    } catch (_) {
      _loans = [...seedLoans];
      _recalculateNextId();
      _persist();
    }
  }

  void _recalculateNextId() {
    _nextId = _loans.isEmpty
        ? 1
        : _loans
        .map((e) => e.id)
        .reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(
        _loans.map((e) => e.toJson()).toList(),
      ),
    );
  }

  String _actualStatus(Loan loan) {
    if (loan.returnedAt != null) {
      return 'returned';
    }

    if (loan.dueAt.isBefore(DateTime.now())) {
      return 'overdue';
    }

    return 'active';
  }

  Loan _withActualStatus(Loan loan) {
    return loan.copyWith(
      status: _actualStatus(loan),
    );
  }

  @override
  Future<PageResult<Loan>> find(LoanQuery q) async {
    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    var rows = _loans.map(_withActualStatus).toList();

    if (q.readerId != null) {
      rows = rows
          .where((loan) => loan.readerId == q.readerId)
          .toList();
    }

    if (q.bookId != null) {
      rows = rows
          .where((loan) => loan.bookId == q.bookId)
          .toList();
    }

    if (q.status != null && q.status!.isNotEmpty) {
      rows = rows
          .where((loan) => loan.status == q.status)
          .toList();
    }

    final search = q.search.trim().toLowerCase();

    if (search.isNotEmpty) {
      rows = rows
          .where(
            (loan) =>
        '${loan.id}'.contains(search) ||
            '${loan.readerId}'.contains(search) ||
            '${loan.bookId}'.contains(search),
      )
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'dueAt' => a.dueAt.compareTo(b.dueAt),
        'status' => a.status.compareTo(b.status),
        _ => a.issuedAt.compareTo(b.issuedAt),
      };

      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size).clamp(0, total);

    final items = from >= total
        ? <Loan>[]
        : rows.sublist(from, to);

    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Loan?> findById(int id) async {
    try {
      return _withActualStatus(
        _loans.firstWhere(
              (loan) => loan.id == id,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Loan> create(Loan loan) async {
    final reader = await _readerRepository.findById(
      loan.readerId,
    );

    if (reader == null || reader.isDeleted) {
      throw StateError('Читатель не найден');
    }

    final book = await _bookRepository.findById(
      loan.bookId,
    );

    if (book == null || book.isDeleted) {
      throw StateError('Книга не найдена');
    }

    if (book.copiesAvailable <= 0) {
      throw StateError(
        'Нет доступных экземпляров книги',
      );
    }

    final duplicateActiveLoan = _loans.any(
          (existing) =>
      existing.readerId == loan.readerId &&
          existing.bookId == loan.bookId &&
          existing.returnedAt == null,
    );

    if (duplicateActiveLoan) {
      throw StateError(
        'У читателя уже есть активная выдача этой книги',
      );
    }

    final created = Loan(
      id: _nextId++,
      readerId: loan.readerId,
      bookId: loan.bookId,
      issuedAt: loan.issuedAt,
      dueAt: loan.dueAt,
      returnedAt: null,
      status: 'active',
    );

    _loans.add(created);

    await _bookRepository.update(
      book.copyWith(
        copiesAvailable: book.copiesAvailable - 1,
      ),
    );

    await _persist();

    return created;
  }

  @override
  Future<Loan> update(Loan loan) async {
    final index = _loans.indexWhere(
          (existing) => existing.id == loan.id,
    );

    if (index == -1) {
      throw StateError(
        'Выдача ${loan.id} не найдена',
      );
    }

    final old = _loans[index];

    if (old.returnedAt == null &&
        loan.returnedAt != null) {
      await _returnBookCopy(old.bookId);
    }

    _loans[index] = _withActualStatus(loan);

    await _persist();

    return _loans[index];
  }

  @override
  Future<Loan> returnLoan(int id) async {
    final index = _loans.indexWhere(
          (loan) => loan.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Выдача $id не найдена',
      );
    }

    final loan = _loans[index];

    if (loan.returnedAt != null) {
      return _withActualStatus(loan);
    }

    await _returnBookCopy(loan.bookId);

    final returned = loan.copyWith(
      returnedAt: DateTime.now(),
      status: 'returned',
    );

    _loans[index] = returned;

    await _persist();

    return returned;
  }

  Future<void> _returnBookCopy(int bookId) async {
    final book = await _bookRepository.findById(bookId);

    if (book == null) {
      return;
    }

    final available = (book.copiesAvailable + 1)
        .clamp(0, book.copiesTotal);

    await _bookRepository.update(
      book.copyWith(
        copiesAvailable: available,
      ),
    );
  }
}