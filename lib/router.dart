import 'package:go_router/go_router.dart';

import 'models/author_query.dart';
import 'models/book_query.dart';
import 'screens/author_detail_screen.dart';
import 'screens/author_list_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/not_found_screen.dart';

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
            yearFrom: int.tryParse(p['yearFrom'] ?? ''),
            yearTo: int.tryParse(p['yearTo'] ?? ''),
            sortField: sortParts != null && sortParts.isNotEmpty
                ? sortParts[0]
                : 'title',
            sortAscending: sortParts == null ||
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
                : 'lastName',
            sortAscending: sortParts == null ||
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
      path: '/authors/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AuthorDetailScreen(id: id);
      },
    ),
  ],
  errorBuilder: (context, state) {
    return NotFoundScreen(
      location: state.uri.toString(),
    );
  },
);