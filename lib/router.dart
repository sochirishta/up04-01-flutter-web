import 'package:go_router/go_router.dart';
import 'package:up04_01_flutter_web/screens/author_form_screen.dart';

import 'models/author_query.dart';
import 'models/book_query.dart';
import 'screens/author_detail_screen.dart';
import 'screens/author_list_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/book_list_screen.dart';
import 'models/genre_query.dart';
import 'screens/genre_detail_screen.dart';
import 'screens/genre_form_screen.dart';
import 'screens/genre_list_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/book_form_screen.dart';
import 'models/publisher_query.dart';
import 'screens/publisher_detail_screen.dart';
import 'screens/publisher_form_screen.dart';
import 'screens/publisher_list_screen.dart';
import 'screens/reader_detail_screen.dart';
import 'screens/reader_form_screen.dart';
import 'screens/reader_list_screen.dart';
import 'models/reader_query.dart';
import 'screens/loan_detail_screen.dart';
import 'screens/loan_list_screen.dart';
import 'models/loan_query.dart';
import 'screens/loan_form_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/books',
  routes: [
    GoRoute(
      path: '/books',
      builder: (context, state) {
        final p = state.uri.queryParameters;
        final sortParts = p['sort']?.split(',');

        return BookListScreen(
          initialQuery: BookQuery(
            search: p['search'] ?? '',
            genreId: int.tryParse(p['genreId'] ?? ''),
            publisherId: int.tryParse(p['publisherId'] ?? ''),
            authorId: int.tryParse(p['authorId'] ?? ''),
            yearFrom: int.tryParse(p['yearFrom'] ?? ''),
            yearTo: int.tryParse(p['yearTo'] ?? ''),
            available: p['available'] == null ? null : p['available'] == 'true',
            sortField: sortParts != null && sortParts.isNotEmpty
                ? sortParts[0]
                : 'title',
            sortAscending:
                sortParts == null ||
                sortParts.length < 2 ||
                sortParts[1] != 'desc',
            page: int.tryParse(p['page'] ?? '') ?? 1,
            size: int.tryParse(p['size'] ?? '') ?? 10,
            includeDeleted: p['deleted'] == 'true',
          ),
        );
      },
    ),
    GoRoute(
      path: '/books/new',
      builder: (context, state) => const BookFormScreen(),
    ),
    GoRoute(
      path: '/books/:id/edit',
      builder: (context, state) =>
          BookFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
    ),
    GoRoute(
      path: '/books/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return BookDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/authors',
      builder: (context, state) {
        final p = state.uri.queryParameters;
        final sortParts = p['sort']?.split(',');

        return AuthorListScreen(
          initialQuery: AuthorQuery(
            search: p['search'] ?? '',
            sortField: sortParts != null && sortParts.isNotEmpty
                ? sortParts[0]
                : 'fullName',
            sortAscending:
                sortParts == null ||
                sortParts.length < 2 ||
                sortParts[1] != 'desc',
            page: int.tryParse(p['page'] ?? '') ?? 1,
            size: int.tryParse(p['size'] ?? '') ?? 10,
            includeDeleted: p['deleted'] == 'true',
          ),
        );
      },
    ),
    GoRoute(
      path: '/genres',
      builder: (context, state) {
        final p = state.uri.queryParameters;
        final sortParts = p['sort']?.split(',');

        return GenreListScreen(
          initialQuery: GenreQuery(
            search: p['search'] ?? '',
            sortField: sortParts != null && sortParts.isNotEmpty
                ? sortParts[0]
                : 'name',
            sortAscending:
            sortParts == null ||
                sortParts.length < 2 ||
                sortParts[1] != 'desc',
            page: int.tryParse(p['page'] ?? '') ?? 1,
            size: int.tryParse(p['size'] ?? '') ?? 10,
            includeDeleted: p['deleted'] == 'true',
          ),
        );
      },
    ),
    GoRoute(
      path: '/genres/new',
      builder: (context, state) => const GenreFormScreen(),
    ),
    GoRoute(
      path: '/genres/:id/edit',
      builder: (context, state) {
        return GenreFormScreen(
          id: int.tryParse(
            state.pathParameters['id'] ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/genres/:id',
      builder: (context, state) {
        final id = int.parse(
          state.pathParameters['id']!,
        );

        return GenreDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/authors/new',
      builder: (context, state) => const AuthorFormScreen(),
    ),
    GoRoute(
      path: '/authors/:id/edit',
      builder: (context, state) =>
          AuthorFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
    ),
    GoRoute(
      path: '/authors/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AuthorDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/publishers',
      builder: (context, state) {
        final p = state.uri.queryParameters;
        final sortParts = p['sort']?.split(',');
        return PublisherListScreen(
          initialQuery: PublisherQuery(
            search: p['search'] ?? '',
            sortField:
            sortParts != null &&
                sortParts.isNotEmpty
                ? sortParts[0]
                : 'name',
            sortAscending:
            sortParts == null ||
                sortParts.length < 2 ||
                sortParts[1] != 'desc',
            page:
            int.tryParse(
              p['page'] ?? '',
            ) ??
                1,
            size:
            int.tryParse(
              p['size'] ?? '',
            ) ??
                10,
            includeDeleted:
            p['deleted'] == 'true',
          ),
        );
      },
    ),
    GoRoute(
      path: '/publishers/new',
      builder: (context, state) =>
      const PublisherFormScreen(),
    ),
    GoRoute(
      path: '/publishers/:id/edit',
      builder: (context, state) {
        return PublisherFormScreen(
          id: int.tryParse(
            state.pathParameters['id'] ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/publishers/:id',
      builder: (context, state) {
        final id = int.parse(
          state.pathParameters['id']!,
        );

        return PublisherDetailScreen(
          id: id,
        );
      },
    ),
    GoRoute(
      path: '/readers',
      builder: (context, state) {
        final p = state.uri.queryParameters;
        final sortParts = p['sort']?.split(',');
        return ReaderListScreen(
          initialQuery: ReaderQuery(
            search: p['search'] ?? '',
            sortField:
            sortParts != null &&
                sortParts.isNotEmpty
                ? sortParts[0]
                : 'fullName',
            sortAscending:
            sortParts == null ||
                sortParts.length < 2 ||
                sortParts[1] != 'desc',
            page:
            int.tryParse(p['page'] ?? '') ?? 1,
            size:
            int.tryParse(p['size'] ?? '') ?? 10,
            includeDeleted:
            p['deleted'] == 'true',
          ),
        );
      },
    ),
    GoRoute(
      path: '/readers/new',
      builder: (context, state) =>
      const ReaderFormScreen(),
    ),
    GoRoute(
      path: '/readers/:id/edit',
      builder: (context, state) =>
          ReaderFormScreen(
            id: int.tryParse(
              state.pathParameters['id'] ?? '',
            ),
          ),
    ),
    GoRoute(
      path: '/readers/:id',
      builder: (context, state) =>
          ReaderDetailScreen(
            id: int.parse(
              state.pathParameters['id']!,
            ),
          ),
    ),
    GoRoute(
      path: '/loans',
      builder: (context, state) {
        final p = state.uri.queryParameters;
        final sortParts = p['sort']?.split(',');
        return LoanListScreen(
          initialQuery: LoanQuery(
            search: p['search'] ?? '',
            status: p['status'],
            readerId:
            int.tryParse(p['readerId'] ?? ''),
            bookId:
            int.tryParse(p['bookId'] ?? ''),
            sortField:
            sortParts != null &&
                sortParts.isNotEmpty
                ? sortParts[0]
                : 'issuedAt',
            sortAscending:
            sortParts != null &&
                sortParts.length > 1 &&
                sortParts[1] == 'asc',
            page:
            int.tryParse(p['page'] ?? '') ?? 1,
            size:
            int.tryParse(p['size'] ?? '') ?? 10,
          ),
        );
      },
    ),
    GoRoute(
      path: '/loans/new',
      builder: (context, state) =>
      const LoanFormScreen(),
    ),
    GoRoute(
      path: '/loans/:id/edit',
      builder: (context, state) =>
          LoanFormScreen(
            id: int.tryParse(
              state.pathParameters['id'] ?? '',
            ),
          ),
    ),
    GoRoute(
      path: '/loans/:id',
      builder: (context, state) =>
          LoanDetailScreen(
            id: int.parse(
              state.pathParameters['id']!,
            ),
          ),
    ),
  ],
  errorBuilder: (context, state) {
    return NotFoundScreen(location: state.uri.toString());
  },
);
