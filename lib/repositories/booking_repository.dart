import 'package:dio/dio.dart';

import '../models/booking.dart';
import '../models/booking_query.dart';
import '../models/page_result.dart';

abstract interface class BookingRepository {
  Future<PageResult<Booking>> find(
      BookingQuery query, {
        CancelToken? cancelToken,
      });

  Future<Booking?> findById(String id);

  Future<Booking?> create(Booking booking);

  Future<Booking?> update(Booking booking);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids);
}