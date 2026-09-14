import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'models/author_query.dart';
import 'models/book_query.dart';
import 'models/genre_query.dart';
import 'models/loan_query.dart';
import 'models/publisher_query.dart';
import 'models/reader_query.dart';
import 'models/app_user.dart';

import 'state/auth_notifier.dart';

import 'screens/admin_users_screen.dart';
import 'screens/reader_profile_screen.dart';
import 'screens/author_detail_screen.dart';
import 'screens/author_form_screen.dart';
import 'screens/author_list_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/genre_detail_screen.dart';
import 'screens/genre_form_screen.dart';
import 'screens/genre_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/loan_detail_screen.dart';
import 'screens/loan_form_screen.dart';
import 'screens/loan_list_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/publisher_detail_screen.dart';
import 'screens/publisher_form_screen.dart';
import 'screens/publisher_list_screen.dart';
import 'screens/reader_detail_screen.dart';
import 'screens/reader_form_screen.dart';
import 'screens/reader_list_screen.dart';
import 'package:flutter/material.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }

      if (loggedIn && isPublic) {
        final from = state.uri.queryParameters['from'];

        if (from != null && from.isNotEmpty) {
          return from;
        }

        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/my-profile',
        redirect: (context, state) {
          return auth.isExactly(Role.reader) ? null : '/forbidden';
        },
        builder: (context, state) => const ReaderProfileScreen(),
      ),

      GoRoute(
        path: '/admin/users',
        redirect: (context, state) {
          return auth.isExactly(Role.admin) ? null : '/forbidden';
        },
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/books',
        redirect: (context, state) {
          return auth.has(Role.reader) ? null : '/forbidden';
        },
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
              available: p['available'] == null
                  ? null
                  : p['available'] == 'true',
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
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) => const BookFormScreen(),
      ),
      GoRoute(
        path: '/books/:id/edit',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) =>
            BookFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path: '/books/:id',
        redirect: (context, state) {
          return auth.has(Role.reader) ? null : '/forbidden';
        },
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return BookDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/authors',
        redirect: (context, state) {
          return auth.has(Role.reader) ? null : '/forbidden';
        },
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
        path: '/authors/new',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) => const AuthorFormScreen(),
      ),
      GoRoute(
        path: '/authors/:id/edit',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) => AuthorFormScreen(
          id: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/authors/:id',
        redirect: (context, state) {
          return auth.has(Role.reader) ? null : '/forbidden';
        },
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AuthorDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/genres',
        redirect: (context, state) {
          return auth.has(Role.reader) ? null : '/forbidden';
        },
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
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) => const GenreFormScreen(),
      ),
      GoRoute(
        path: '/genres/:id/edit',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) =>
            GenreFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path: '/genres/:id',
        redirect: (context, state) {
          return auth.has(Role.reader) ? null : '/forbidden';
        },
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return GenreDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/publishers',
        redirect: (context, state) {
          return auth.has(Role.reader) ? null : '/forbidden';
        },
        builder: (context, state) {
          final p = state.uri.queryParameters;
          final sortParts = p['sort']?.split(',');

          return PublisherListScreen(
            initialQuery: PublisherQuery(
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
        path: '/publishers/new',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) => const PublisherFormScreen(),
      ),
      GoRoute(
        path: '/publishers/:id/edit',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) => PublisherFormScreen(
          id: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/publishers/:id',
        redirect: (context, state) {
          return auth.has(Role.reader) ? null : '/forbidden';
        },
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PublisherDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/readers',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) {
          final p = state.uri.queryParameters;
          final sortParts = p['sort']?.split(',');

          return ReaderListScreen(
            initialQuery: ReaderQuery(
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
        path: '/readers/new',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) => const ReaderFormScreen(),
      ),
      GoRoute(
        path: '/readers/:id/edit',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) => ReaderFormScreen(
          id: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/readers/:id',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) =>
            ReaderDetailScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/loans',
        redirect: (context, state) {
          return auth.has(Role.reader) ? null : '/forbidden';
        },
        builder: (context, state) {
          final p = state.uri.queryParameters;
          final sortParts = p['sort']?.split(',');

          return LoanListScreen(
            initialQuery: LoanQuery(
              search: p['search'] ?? '',
              status: p['status'],
              readerId: int.tryParse(p['readerId'] ?? ''),
              bookId: int.tryParse(p['bookId'] ?? ''),
              sortField: sortParts != null && sortParts.isNotEmpty
                  ? sortParts[0]
                  : 'issuedAt',
              sortAscending:
                  sortParts != null &&
                  sortParts.length > 1 &&
                  sortParts[1] == 'asc',
              page: int.tryParse(p['page'] ?? '') ?? 1,
              size: int.tryParse(p['size'] ?? '') ?? 10,
            ),
          );
        },
      ),
      GoRoute(
        path: '/loans/new',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) => const LoanFormScreen(),
      ),
      GoRoute(
        path: '/loans/:id/edit',
        redirect: (context, state) {
          return auth.has(Role.librarian) ? null : '/forbidden';
        },
        builder: (context, state) =>
            LoanFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path: '/loans/:id',
        redirect: (context, state) {
          return auth.has(Role.reader) ? null : '/forbidden';
        },
        builder: (context, state) =>
            LoanDetailScreen(id: int.parse(state.pathParameters['id']!)),
      ),
    ],
    errorBuilder: (context, state) {
      return NotFoundScreen(location: state.uri.toString());
    },
  );
}
