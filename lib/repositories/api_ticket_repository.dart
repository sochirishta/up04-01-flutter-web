import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/ticket.dart';
import '../models/ticket_query.dart';
import 'ticket_repository.dart';

class ApiTicketRepository implements TicketRepository {
  final Dio _dio;

  ApiTicketRepository(this._dio);

  @override
  Future<PageResult<Ticket>> find(
      TicketQuery q, {
        CancelToken? cancelToken,
      }) {
    return guard(() async {
      final filters = <String>[];

      if (q.search.trim().isNotEmpty) {
        final value = q.search.trim().replaceAll('"', r'\"');
        filters.add('number ~ "$value"');
      }

      if (q.bookingId != null && q.bookingId!.isNotEmpty) {
        filters.add('booking = "${q.bookingId}"');
      }

      if (!q.includeDeleted) {
        filters.add('deletedAt = ""');
      }

      final response = await _dio.get(
        '/collections/tickets/records',
        queryParameters: {
          'page': q.page,
          'perPage': q.size,
          'sort': '${q.sortAscending ? '+' : '-'}${q.sortField}',
          if (filters.isNotEmpty) 'filter': filters.join(' && '),
          'expand': 'booking',
        },
        cancelToken: cancelToken,
      );

      return _pageResult(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Ticket?> findById(String id) {
    return guard(() async {
      final response = await _dio.get(
        '/collections/tickets/records/$id',
        queryParameters: {
          'expand': 'booking',
        },
      );

      return Ticket.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Ticket?> create(Ticket ticket) {
    return guard(() async {
      final response = await _dio.post(
        '/collections/tickets/records',
        data: {
          'booking': ticket.bookingId,
          'number': ticket.number,
          'issuedAt': ticket.issuedAt.toUtc().toIso8601String(),
          'deletedAt': '',
        },
      );

      return Ticket.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Ticket?> update(Ticket ticket) {
    return guard(() async {
      final response = await _dio.patch(
        '/collections/tickets/records/${ticket.id}',
        data: {
          'booking': ticket.bookingId,
          'number': ticket.number,
          'issuedAt': ticket.issuedAt.toUtc().toIso8601String(),
        },
      );

      return Ticket.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<void> softDelete(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/tickets/records/$id',
        data: {
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    });
  }

  @override
  Future<void> hardDelete(String id) {
    return guard(() async {
      await _dio.delete(
        '/collections/tickets/records/$id',
      );
    });
  }

  @override
  Future<void> restore(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/tickets/records/$id',
        data: {
          'deletedAt': '',
        },
      );
    });
  }

  @override
  Future<int> deleteMany(List<String> ids) async {
    var count = 0;

    for (final id in ids) {
      try {
        await softDelete(id);
        count++;
      } on ApiException {
        // Continue with the remaining records.
      }
    }

    return count;
  }

  PageResult<Ticket> _pageResult(
      Map<String, dynamic> data,
      ) {
    final items = (data['items'] as List<dynamic>)
        .map(
          (item) => Ticket.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();

    return PageResult<Ticket>(
      items: items,
      page: (data['page'] as num).toInt(),
      size: (data['perPage'] as num).toInt(),
      total: (data['totalItems'] as num).toInt(),
    );
  }
}