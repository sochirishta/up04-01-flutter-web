import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:up04_01_flutter_web/core/auth_api.dart';
import 'package:up04_01_flutter_web/models/app_user.dart';
import 'package:up04_01_flutter_web/models/author.dart';
import 'package:up04_01_flutter_web/models/author_query.dart';
import 'package:up04_01_flutter_web/models/book.dart';
import 'package:up04_01_flutter_web/models/book_query.dart';
import 'package:up04_01_flutter_web/models/genre.dart';
import 'package:up04_01_flutter_web/models/genre_query.dart';
import 'package:up04_01_flutter_web/models/page_result.dart';
import 'package:up04_01_flutter_web/models/publisher.dart';
import 'package:up04_01_flutter_web/models/publisher_query.dart';

import 'package:up04_01_flutter_web/repositories/author_repository.dart';
import 'package:up04_01_flutter_web/repositories/book_repository.dart';
import 'package:up04_01_flutter_web/repositories/genre_repository.dart';
import 'package:up04_01_flutter_web/repositories/publisher_repository.dart';

import 'package:up04_01_flutter_web/screens/book_list_screen.dart';
import 'package:up04_01_flutter_web/state/auth_notifier.dart';
import 'package:up04_01_flutter_web/state/book_list_notifier.dart';
import 'package:up04_01_flutter_web/state/reference_cache.dart';

import 'package:up04_01_flutter_web/widgets/app_navigation_drawer.dart';
import 'package:up04_01_flutter_web/widgets/entity_form.dart';
import 'package:up04_01_flutter_web/widgets/form_field_definition.dart';

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('widget tests', () {
    testWidgets('EntityForm shows loading indicator while loading', (
        tester,
        ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EntityForm(
            formKey: GlobalKey<FormState>(),
            title: 'Книга',
            isEditing: false,
            isLoading: true,
            isSaving: false,
            hasUnsavedChanges: false,
            onSubmit: () {},
            onCancel: () {},
            fields: const [],
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Книга'), findsOneWidget);
    });

    testWidgets('EntityForm shows validation error', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: EntityForm(
            formKey: formKey,
            title: 'Книга',
            isEditing: false,
            isLoading: false,
            isSaving: false,
            hasUnsavedChanges: false,
            onSubmit: () {
              formKey.currentState!.validate();
            },
            onCancel: () {},
            fields: [
              FormFieldDefinition(
                label: 'Название',
                type: FormFieldType.text,
                controller: controller,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Поле обязательно';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Создать'));
      await tester.pump();

      expect(find.text('Поле обязательно'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Reader does not see librarian and admin navigation items', (
        tester,
        ) async {
      final auth = _FakeAuthNotifier(
        prefs,
        AppUser(
          id: 1,
          username: 'reader',
          fullName: 'Reader',
          role: Role.reader,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthNotifier>.value(
          value: auth,
          child: MaterialApp(
            home: Scaffold(
              drawer: const AppNavigationDrawer(
                currentRoute: '/books',
              ),
            ),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(
        find.byType(Scaffold),
      );

      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Книги'), findsOneWidget);
      expect(find.text('Авторы'), findsOneWidget);
      expect(find.text('Жанры'), findsOneWidget);
      expect(find.text('Издательства'), findsOneWidget);
      expect(find.text('Выдачи'), findsOneWidget);

      expect(find.text('Читатели'), findsNothing);
      expect(find.text('Пользователи'), findsNothing);
    });

    testWidgets('BookListScreen shows empty state', (tester) async {
      final bookRepository = _FakeBookRepository();
      final references = _FakeReferenceCache();

      await _pumpBookListScreen(
        tester,
        bookRepository: bookRepository,
        references: references,
        prefs: prefs,
      );

      await tester.pumpAndSettle();

      expect(find.text('Книг не найдено'), findsOneWidget);
    });

    testWidgets('BookListScreen shows error and retries successfully', (
        tester,
        ) async {
      final bookRepository = _FakeBookRepository(
        failFirstFind: true,
      );
      final references = _FakeReferenceCache();

      await _pumpBookListScreen(
        tester,
        bookRepository: bookRepository,
        references: references,
        prefs: prefs,
      );

      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
      expect(find.text('Книг не найдено'), findsNothing);

      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('Повторить'), findsNothing);
      expect(find.text('Книг не найдено'), findsOneWidget);
    });
  });
}

Future<void> _pumpBookListScreen(
    WidgetTester tester, {
      required BookRepository bookRepository,
      required ReferenceCache references,
      required SharedPreferences prefs,
    }) async {
  final auth = _FakeAuthNotifier(
    prefs,
    AppUser(
      id: 1,
      username: 'reader',
      fullName: 'Reader',
      role: Role.reader,
    ),
  );

  final bookNotifier = BookListNotifier(bookRepository);

  final router = GoRouter(
    initialLocation: '/books',
    routes: [
      GoRoute(
        path: '/books',
        builder: (context, state) {
          return const BookListScreen(
            initialQuery: BookQuery(),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(
          value: auth,
        ),
        Provider<BookRepository>.value(
          value: bookRepository,
        ),
        ChangeNotifierProvider<BookListNotifier>.value(
          value: bookNotifier,
        ),
        ChangeNotifierProvider<ReferenceCache>.value(
          value: references,
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );

  addTearDown(() {
    router.dispose();
    bookNotifier.dispose();
    auth.dispose();
    references.dispose();
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(
      SharedPreferences prefs,
      this._fakeUser,
      ) : super(
    prefs,
    AuthApi(Dio()),
  );

  final AppUser _fakeUser;

  @override
  AppUser? get user => _fakeUser;
}

class _FakeBookRepository implements BookRepository {
  _FakeBookRepository({
    this.failFirstFind = false,
  });

  final bool failFirstFind;
  bool _failed = false;

  @override
  Future<PageResult<Book>> find(
      BookQuery query, {
        CancelToken? cancelToken,
      }) async {
    if (failFirstFind && query.size != 10000 && !_failed) {
      _failed = true;
      throw Exception('Ошибка загрузки книг');
    }

    return PageResult.empty();
  }

  @override
  Future<Book?> findById(int id) async => null;

  @override
  Future<Book?> create(Book book) async => book;

  @override
  Future<Book?> update(Book book) async => book;

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> hardDelete(int id) async {}

  @override
  Future<void> restore(int id) async {}

  @override
  Future<int> deleteMany(List<int> ids) async => ids.length;
}

class _FakeReferenceCache extends ReferenceCache {
  _FakeReferenceCache()
      : super(
    _FakeAuthorRepository(),
    _FakeGenreRepository(),
    _FakePublisherRepository(),
  );
}

class _FakeAuthorRepository implements AuthorRepository {
  @override
  Future<PageResult<Author>> find(
      AuthorQuery query, {
        CancelToken? cancelToken,
      }) async {
    return PageResult.empty();
  }

  @override
  Future<Author?> findById(int id) async => null;

  @override
  Future<Author?> create(Author author) async => author;

  @override
  Future<Author?> update(Author author) async => author;

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> hardDelete(int id) async {}

  @override
  Future<void> restore(int id) async {}

  @override
  Future<int> deleteMany(List<int> ids) async => ids.length;
}

class _FakeGenreRepository implements GenreRepository {
  @override
  Future<PageResult<Genre>> find(
      GenreQuery query, {
        CancelToken? cancelToken,
      }) async {
    return PageResult.empty();
  }

  @override
  Future<Genre?> findById(int id) async => null;

  @override
  Future<Genre> create(Genre genre) async => genre;

  @override
  Future<Genre> update(Genre genre) async => genre;

  @override
  Future<void> delete(int id) async {}

  @override
  Future<int> deleteMany(List<int> ids) async => ids.length;

  @override
  Future<void> restore(int id) async {}

  @override
  Future<void> hardDelete(int id) async {}
}

class _FakePublisherRepository implements PublisherRepository {
  @override
  Future<PageResult<Publisher>> find(
      PublisherQuery query, {
        CancelToken? cancelToken,
      }) async {
    return PageResult.empty();
  }

  @override
  Future<Publisher?> findById(int id) async => null;

  @override
  Future<Publisher> create(Publisher publisher) async => publisher;

  @override
  Future<Publisher> update(Publisher publisher) async => publisher;

  @override
  Future<void> delete(int id) async {}

  @override
  Future<int> deleteMany(List<int> ids) async => ids.length;

  @override
  Future<void> restore(int id) async {}

  @override
  Future<void> hardDelete(int id) async {}
}