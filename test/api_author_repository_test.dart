import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:up04_01_flutter_web/core/api_exceptions.dart';
import 'package:up04_01_flutter_web/models/author.dart';
import 'package:up04_01_flutter_web/models/author_query.dart';
import 'package:up04_01_flutter_web/repositories/api_author_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late ApiAuthorRepository repository;

  setUp(() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8080/api',
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final status = response.statusCode ?? 0;

          if (status >= 400) {
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: mapHttpError(status, response.data),
              ),
              true,
            );
          }

          return handler.next(response);
        },
      ),
    );

    dioAdapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = dioAdapter;

    repository = ApiAuthorRepository(dio);
  });

  group('ApiAuthorRepository', () {
    test('find parses successful response', () async {
      dioAdapter.onGet(
        '/authors',
        (server) => server.reply(200, {
          'items': [
            {
              'id': 1,
              'fullName': 'George Orwell',
              'birthYear': 1903,
              'country': 'United Kingdom',
              'deletedAt': null,
            },
            {
              'id': 2,
              'fullName': 'Fyodor Dostoevsky',
              'birthYear': 1821,
              'country': 'Russia',
              'deletedAt': null,
            },
          ],
          'page': 1,
          'size': 10,
          'total': 2,
        }),
        queryParameters: {'sort': 'fullName,asc', 'page': 1, 'size': 10},
      );

      final result = await repository.find(const AuthorQuery());

      expect(result.items.length, 2);
      expect(result.page, 1);
      expect(result.size, 10);
      expect(result.total, 2);

      expect(result.items[0].fullName, 'George Orwell');
      expect(result.items[1].fullName, 'Fyodor Dostoevsky');
    });

    test('find sends search, sorting and pagination parameters', () async {
      dioAdapter.onGet(
        '/authors',
        (server) => server.reply(200, {
          'items': [
            {
              'id': 5,
              'fullName': 'George Martin',
              'birthYear': 1948,
              'country': 'United States',
              'deletedAt': null,
            },
          ],
          'page': 2,
          'size': 5,
          'total': 1,
        }),
        queryParameters: {
          'search': 'George',
          'sort': 'fullName,desc',
          'page': 2,
          'size': 5,
          'includeDeleted': true,
        },
      );

      final result = await repository.find(
        const AuthorQuery(
          search: 'George',
          sortField: 'fullName',
          sortAscending: false,
          page: 2,
          size: 5,
          includeDeleted: true,
        ),
      );

      expect(result.items.single.fullName, 'George Martin');
      expect(result.page, 2);
      expect(result.size, 5);
    });

    test('create sends author data and returns created author', () async {
      dioAdapter.onPost(
        '/authors',
        (server) => server.reply(201, {
          'id': 10,
          'fullName': 'Isaac Asimov',
          'birthYear': 1920,
          'country': 'Russia',
          'deletedAt': null,
        }),
        data: {
          'fullName': 'Isaac Asimov',
          'birthYear': 1920,
          'country': 'Russia',
        },
      );

      final result = await repository.create(
        const Author(
          id: 0,
          fullName: 'Isaac Asimov',
          birthYear: 1920,
          country: 'Russia',
        ),
      );

      expect(result, isNotNull);
      expect(result!.id, 10);
      expect(result.fullName, 'Isaac Asimov');
    });

    test('422 response is mapped to ValidationException', () async {
      dioAdapter.onPost(
        '/authors',
        (server) => server.reply(422, {
          'message': 'Ошибка валидации',
          'errors': {
            'fullName': 'Имя автора обязательно',
            'birthYear': 'Некорректный год рождения',
          },
        }),
        data: {'fullName': '', 'birthYear': 0, 'country': 'Russia'},
      );

      expect(
        () => repository.create(
          const Author(id: 0, fullName: '', birthYear: 0, country: 'Russia'),
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.errors,
            'errors',
            containsPair('fullName', 'Имя автора обязательно'),
          ),
        ),
      );
    });

    test('server unavailable is mapped to NetworkException', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );

      expect(() => repository.findById(999), throwsA(isA<NetworkException>()));
    });
  });
}