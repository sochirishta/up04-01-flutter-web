import 'package:dio/dio.dart';
import 'package:up04_01_flutter_web/models/loan.dart';
import 'package:up04_01_flutter_web/models/loan_query.dart';
import 'package:up04_01_flutter_web/models/page_result.dart';
import 'package:up04_01_flutter_web/repositories/loan_repository.dart';

import '../core/api_exceptions.dart';

class ApiLoanRepository implements LoanRepository {
  final Dio _dio;

  ApiLoanRepository(this._dio);

  @override
  Future<PageResult<Loan>> find(LoanQuery q) {
    return guard(() async {
      final response = await _dio.get(
        '/loans',
        queryParameters: {
          if (q.readerId != null) 'readerId': q.readerId,
          if (q.bookId != null) 'bookId': q.bookId,
          if (q.status != null && q.status!.isNotEmpty) 'status': q.status,
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
        },
      );

      final data = response.data as Map<String, dynamic>;

      final items = (data['items'] as List)
          .map((item) => Loan.fromJson(item as Map<String, dynamic>))
          .toList();

      return PageResult<Loan>(
        items: items,
        page: data['page'] as int,
        size: data['size'] as int,
        total: data['total'] as int,
      );
    });
  }

  @override
  Future<Loan?> findById(int id) {
    return guard(() async {
      final response = await _dio.get('/loans/$id');

      return Loan.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Loan> create(Loan loan) {
    return guard(() async {
      final days = loan.dueAt.difference(loan.issuedAt).inDays;

      final response = await _dio.post(
        '/loans',
        data: {'readerId': loan.readerId, 'bookId': loan.bookId, 'days': days},
      );

      return Loan.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Loan> update(Loan loan) {
    return guard(() async {
      final response = await _dio.put(
        '/loans/${loan.id}',
        data: {
          'readerId': loan.readerId,
          'bookId': loan.bookId,
          'issuedAt': loan.issuedAt.toIso8601String(),
          'dueAt': loan.dueAt.toIso8601String(),
          'returnedAt': loan.returnedAt?.toIso8601String(),
        },
      );

      return Loan.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Loan> returnLoan(int id) {
    return guard(() async {
      final response = await _dio.post('/loans/$id/return');

      return Loan.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
