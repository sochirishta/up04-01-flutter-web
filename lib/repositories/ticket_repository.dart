import 'package:dio/dio.dart';

import '../models/page_result.dart';
import '../models/ticket.dart';
import '../models/ticket_query.dart';

abstract interface class TicketRepository {
  Future<PageResult<Ticket>> find(
      TicketQuery query, {
        CancelToken? cancelToken,
      });

  Future<Ticket?> findById(String id);

  Future<Ticket?> create(Ticket ticket);

  Future<Ticket?> update(Ticket ticket);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids);
}