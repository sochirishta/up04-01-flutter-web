import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/booking.dart';
import '../models/booking_query.dart';
import '../models/page_result.dart';
import 'booking_repository.dart';

class ApiBookingRepository implements BookingRepository {
  final Dio _dio;

  ApiBookingRepository(this._dio);

  @override
  Future<PageResult<Booking>> find(
      BookingQuery q, {
        CancelToken? cancelToken,
      }) {
    return guard(() async {
      final filters = <String>[];

      if (q.sessionId != null && q.sessionId!.isNotEmpty) {
        filters.add('session = "${q.sessionId}"');
      }

      if (q.userId != null && q.userId!.isNotEmpty) {
        filters.add('user = "${q.userId}"');
      }

      if (q.row != null) {
        filters.add('row = ${q.row}');
      }

      if (q.seat != null) {
        filters.add('seat = ${q.seat}');
      }

      if (!q.includeDeleted) {
        filters.add('deletedAt = ""');
      }

      final response = await _dio.get(
        '/collections/bookings/records',
        queryParameters: {
          'page': q.page,
          'perPage': q.size,
          'sort': '${q.sortAscending ? '+' : '-'}${q.sortField}',
          if (filters.isNotEmpty) 'filter': filters.join(' && '),
          'expand': 'session,user',
        },
        cancelToken: cancelToken,
      );

      return _pageResult(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Booking?> findById(String id) {
    return guard(() async {
      final response = await _dio.get(
        '/collections/bookings/records/$id',
        queryParameters: {
          'expand': 'session,user',
        },
      );

      return Booking.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Booking?> create(Booking booking) {
    return guard(() async {
      final response = await _dio.post(
        '/collections/bookings/records',
        data: {
          'session': booking.sessionId,
          'user': booking.userId,
          'row': booking.row,
          'seat': booking.seat,
          'deletedAt': '',
        },
      );

      return Booking.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Booking?> update(Booking booking) {
    return guard(() async {
      final response = await _dio.patch(
        '/collections/bookings/records/${booking.id}',
        data: {
          'session': booking.sessionId,
          'user': booking.userId,
          'row': booking.row,
          'seat': booking.seat,
        },
      );

      return Booking.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<void> softDelete(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/bookings/records/$id',
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
        '/collections/bookings/records/$id',
      );
    });
  }

  @override
  Future<void> restore(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/bookings/records/$id',
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

  PageResult<Booking> _pageResult(
      Map<String, dynamic> data,
      ) {
    final items = (data['items'] as List<dynamic>)
        .map(
          (item) => Booking.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();

    return PageResult<Booking>(
      items: items,
      page: (data['page'] as num).toInt(),
      size: (data['perPage'] as num).toInt(),
      total: (data['totalItems'] as num).toInt(),
    );
  }
}