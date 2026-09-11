import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/loan.dart';
import '../models/loan_query.dart';
import '../models/page_result.dart';
import '../repositories/loan_repository.dart';

enum LoanLoadStatus { idle, loading, success, error }

class LoanListNotifier extends ChangeNotifier {
  LoanListNotifier(this._repository);

  final LoanRepository _repository;

  Timer? _searchDebounce;

  LoanQuery _query = const LoanQuery();
  PageResult<Loan> _result = PageResult.empty();

  LoanLoadStatus _status = LoanLoadStatus.idle;
  String? _errorMessage;

  LoanQuery get query => _query;
  PageResult<Loan> get result => _result;
  LoanLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = LoanLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _repository.find(_query);
      _status = LoanLoadStatus.success;
    } catch (error) {
      _status = LoanLoadStatus.error;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  Future<void> setQuery(LoanQuery value) async {
    _query = value;
    await load();
  }

  void search(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      applyQuery(query.copyWith(search: value.trim(), page: 1));
    });
  }

  Future<void> clearSearch() {
    _searchDebounce?.cancel();

    return applyQuery(query.copyWith(search: '', page: 1));
  }

  Future<void> applyQuery(LoanQuery value) async {
    _query = value;
    await load();
  }

  Future<void> sort(String field) {
    final sameField = query.sortField == field;

    return applyQuery(
      query.copyWith(
        sortField: field,
        sortAscending: sameField ? !query.sortAscending : true,
        page: 1,
      ),
    );
  }

  Future<void> firstPage() {
    return applyQuery(query.copyWith(page: 1));
  }

  Future<void> previousPage() {
    if (query.page <= 1) {
      return Future.value();
    }

    return applyQuery(query.copyWith(page: query.page - 1));
  }

  Future<void> nextPage() {
    if (!result.hasNext) {
      return Future.value();
    }

    return applyQuery(query.copyWith(page: query.page + 1));
  }

  Future<void> lastPage() {
    return applyQuery(query.copyWith(page: result.totalPages));
  }

  Future<void> changePageSize(int size) {
    return applyQuery(query.copyWith(page: 1, size: size));
  }

  Future<void> setStatus(String? status) {
    return applyQuery(query.copyWith(status: status, page: 1));
  }

  Future<void> setReader(int? readerId) {
    return applyQuery(query.copyWith(readerId: readerId, page: 1));
  }

  Future<void> setBook(int? bookId) {
    return applyQuery(query.copyWith(bookId: bookId, page: 1));
  }

  Future<void> createLoan(Loan loan) async {
    await _repository.create(loan);
    await load();
  }

  Future<void> updateLoan(Loan loan) async {
    await _repository.update(loan);
    await load();
  }

  Future<void> returnLoan(int id) async {
    await _repository.returnLoan(id);
    await load();
  }

  Future<Loan?> findById(int id) {
    return _repository.findById(id);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
