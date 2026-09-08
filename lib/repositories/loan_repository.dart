import '../models/loan.dart';
import '../models/loan_query.dart';
import '../models/page_result.dart';

abstract interface class LoanRepository {
  Future<PageResult<Loan>> find(LoanQuery query);

  Future<Loan?> findById(int id);

  Future<Loan> create(Loan loan);

  Future<Loan> update(Loan loan);

  Future<Loan> returnLoan(int id);
}