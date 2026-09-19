import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/app_user.dart';
import 'models/country_query.dart';
import 'models/genre_query.dart';
import 'models/hall_query.dart';
import 'models/movie_query.dart';
import 'models/person_query.dart';
import 'models/session_query.dart';
import 'models/ticket_query.dart';

import 'screens/admin_users_screen.dart';
import 'screens/booking_detail_screen.dart';
import 'screens/booking_form_screen.dart';
import 'screens/booking_list_screen.dart';
import 'screens/country_detail_screen.dart';
import 'screens/country_form_screen.dart';
import 'screens/country_list_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/genre_detail_screen.dart';
import 'screens/genre_form_screen.dart';
import 'screens/genre_list_screen.dart';
import 'screens/hall_detail_screen.dart';
import 'screens/hall_form_screen.dart';
import 'screens/hall_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/movie_form_screen.dart';
import 'screens/movie_list_screen.dart';
import 'screens/person_detail_screen.dart';
import 'screens/person_form_screen.dart';
import 'screens/person_list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/session_detail_screen.dart';
import 'screens/session_form_screen.dart';
import 'screens/session_list_screen.dart';
import 'screens/ticket_detail_screen.dart';
import 'screens/ticket_form_screen.dart';
import 'screens/ticket_list_screen.dart';

import 'state/auth_notifier.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;

      final isPublic =
          target == '/login' || target == '/register';

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
      // ------------------------------------------------------------------
      // Auth
      // ------------------------------------------------------------------

      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),

      // ------------------------------------------------------------------
      // Dashboard
      // ------------------------------------------------------------------

      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),

      // ------------------------------------------------------------------
      // Admin
      // ------------------------------------------------------------------

      GoRoute(
        path: '/admin/users',
        redirect: (context, state) {
          if (!auth.isExactly(Role.admin)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) => const AdminUsersScreen(),
      ),

      // ------------------------------------------------------------------
      // Movies
      // ------------------------------------------------------------------

      GoRoute(
        path: '/movies',
        builder: (context, state) {
          final p = state.uri.queryParameters;
          final sortParts = p['sort']?.split(',');

          return MovieListScreen(
            initialQuery: MovieQuery(
              search: p['search'] ?? '',
              yearFrom: int.tryParse(p['yearFrom'] ?? ''),
              yearTo: int.tryParse(p['yearTo'] ?? ''),
              durationFrom: int.tryParse(p['durationFrom'] ?? ''),
              durationTo: int.tryParse(p['durationTo'] ?? ''),
              genreId: p['genreId'],
              personId: p['personId'],
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
        path: '/movies/new',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) => const MovieFormScreen(),
      ),

      GoRoute(
        path: '/movies/:id/edit',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          return MovieFormScreen(
            id: state.pathParameters['id'],
          );
        },
      ),

      GoRoute(
        path: '/movies/:id',
        builder: (context, state) {
          return MovieDetailScreen(
            id: state.pathParameters['id']!,
          );
        },
      ),

      // ------------------------------------------------------------------
      // Genres
      // ------------------------------------------------------------------

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
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) => const GenreFormScreen(),
      ),

      GoRoute(
        path: '/genres/:id/edit',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          return GenreFormScreen(
            id: state.pathParameters['id'],
          );
        },
      ),

      GoRoute(
        path: '/genres/:id',
        builder: (context, state) {
          return GenreDetailScreen(
            id: state.pathParameters['id']!,
          );
        },
      ),

      // ------------------------------------------------------------------
      // Persons
      // ------------------------------------------------------------------

      GoRoute(
        path: '/persons',
        builder: (context, state) {
          final p = state.uri.queryParameters;
          final sortParts = p['sort']?.split(',');

          return PersonListScreen(
            initialQuery: PersonQuery(
              search: p['search'] ?? '',
              birthYearFrom:
              int.tryParse(p['birthYearFrom'] ?? ''),
              birthYearTo:
              int.tryParse(p['birthYearTo'] ?? ''),
              countryId: p['countryId'],
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
        path: '/persons/new',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) => const PersonFormScreen(),
      ),

      GoRoute(
        path: '/persons/:id/edit',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          return PersonFormScreen(
            id: state.pathParameters['id'],
          );
        },
      ),

      GoRoute(
        path: '/persons/:id',
        builder: (context, state) {
          return PersonDetailScreen(
            id: state.pathParameters['id']!,
          );
        },
      ),

      // ------------------------------------------------------------------
      // Countries
      // ------------------------------------------------------------------

      GoRoute(
        path: '/countries',
        builder: (context, state) {
          final p = state.uri.queryParameters;
          final sortParts = p['sort']?.split(',');

          return CountryListScreen(
            initialQuery: CountryQuery(
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
        path: '/countries/new',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) => const CountryFormScreen(),
      ),

      GoRoute(
        path: '/countries/:id/edit',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          return CountryFormScreen(
            id: state.pathParameters['id'],
          );
        },
      ),

      GoRoute(
        path: '/countries/:id',
        builder: (context, state) {
          return CountryDetailScreen(
            id: state.pathParameters['id']!,
          );
        },
      ),

      // ------------------------------------------------------------------
      // Halls
      // ------------------------------------------------------------------

      GoRoute(
        path: '/halls',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          final p = state.uri.queryParameters;
          final sortParts = p['sort']?.split(',');

          return HallListScreen(
            initialQuery: HallQuery(
              search: p['search'] ?? '',
              capacityFrom:
              int.tryParse(p['capacityFrom'] ?? ''),
              capacityTo:
              int.tryParse(p['capacityTo'] ?? ''),
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
        path: '/halls/new',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) => const HallFormScreen(),
      ),

      GoRoute(
        path: '/halls/:id/edit',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          return HallFormScreen(
            id: state.pathParameters['id'],
          );
        },
      ),

      GoRoute(
        path: '/halls/:id',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          return HallDetailScreen(
            id: state.pathParameters['id']!,
          );
        },
      ),

      // ------------------------------------------------------------------
      // Sessions
      // ------------------------------------------------------------------

      GoRoute(
        path: '/sessions',
        builder: (context, state) {
          final p = state.uri.queryParameters;
          final sortParts = p['sort']?.split(',');

          return SessionListScreen(
            initialQuery: SessionQuery(
              search: p['search'] ?? '',
              movieId: p['movieId'],
              hallId: p['hallId'],
              dateFrom: DateTime.tryParse(p['dateFrom'] ?? ''),
              dateTo: DateTime.tryParse(p['dateTo'] ?? ''),
              sortField: sortParts != null && sortParts.isNotEmpty
                  ? sortParts[0]
                  : 'date',
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
        path: '/sessions/new',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) => const SessionFormScreen(),
      ),

      GoRoute(
        path: '/sessions/:id/edit',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          return SessionFormScreen(
            id: state.pathParameters['id'],
          );
        },
      ),

      GoRoute(
        path: '/sessions/:id',
        builder: (context, state) {
          return SessionDetailScreen(
            id: state.pathParameters['id']!,
          );
        },
      ),

      // ------------------------------------------------------------------
      // Bookings
      // ------------------------------------------------------------------

      GoRoute(
        path: '/bookings',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          return const BookingListScreen();
        },
      ),

      GoRoute(
        path: '/bookings/new',
        redirect: (context, state) {
          if (!auth.hasRole(Role.viewer)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) => const BookingFormScreen(),
      ),

      GoRoute(
        path: '/bookings/:id/edit',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          return BookingFormScreen(
            id: state.pathParameters['id'],
          );
        },
      ),

      GoRoute(
        path: '/bookings/:id',
        builder: (context, state) {
          return BookingDetailScreen(
            id: state.pathParameters['id']!,
          );
        },
      ),

      // ------------------------------------------------------------------
      // Tickets
      // ------------------------------------------------------------------

      GoRoute(
        path: '/tickets',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          final p = state.uri.queryParameters;
          final sortParts = p['sort']?.split(',');

          return TicketListScreen(
            initialQuery: TicketQuery(
              search: p['search'] ?? '',
              bookingId: p['bookingId'],
              sortField: sortParts != null && sortParts.isNotEmpty
                  ? sortParts[0]
                  : 'issuedAt',
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
        path: '/tickets/new',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) => const TicketFormScreen(),
      ),

      GoRoute(
        path: '/tickets/:id/edit',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          return TicketFormScreen(
            id: state.pathParameters['id'],
          );
        },
      ),

      GoRoute(
        path: '/tickets/:id',
        redirect: (context, state) {
          if (!auth.hasRole(Role.manager)) {
            return '/forbidden';
          }

          return null;
        },
        builder: (context, state) {
          return TicketDetailScreen(
            id: state.pathParameters['id']!,
          );
        },
      ),
    ],
  );
}