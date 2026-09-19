import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/auth_api.dart';

import 'repositories/api_booking_repository.dart';
import 'repositories/api_country_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_hall_repository.dart';
import 'repositories/api_movie_repository.dart';
import 'repositories/api_person_repository.dart';
import 'repositories/api_session_repository.dart';
import 'repositories/api_ticket_repository.dart';

import 'repositories/booking_repository.dart';
import 'repositories/country_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/hall_repository.dart';
import 'repositories/movie_repository.dart';
import 'repositories/person_repository.dart';
import 'repositories/session_repository.dart';
import 'repositories/ticket_repository.dart';

import 'state/auth_notifier.dart';
import 'state/booking_list_notifier.dart';
import 'state/country_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/hall_list_notifier.dart';
import 'state/movie_list_notifier.dart';
import 'state/person_list_notifier.dart';
import 'state/reference_cache.dart';
import 'state/session_list_notifier.dart';
import 'state/ticket_list_notifier.dart';

import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  final authDio = buildDio();
  final authApi = AuthApi(authDio);

  final authNotifier = AuthNotifier(authApi);

  await authNotifier.restore();

  final dio = buildDio(
    tokenProvider: () => authNotifier.accessToken,
    refreshToken: () async {
      final refreshed = await authNotifier.refreshTokens();
      if (!refreshed) {
        return null;
      }
      return authNotifier.accessToken;
    },
  );

  final router = buildRouter(authNotifier);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(
          value: authNotifier,
        ),

        Provider<Dio>.value(
          value: dio,
        ),

        ProxyProvider<Dio, MovieRepository>(
          update: (_, dio, previous) => ApiMovieRepository(dio),
        ),
        ChangeNotifierProvider<MovieListNotifier>(
          create: (context) =>
          MovieListNotifier(context.read<MovieRepository>())..load(),
        ),

        ProxyProvider<Dio, GenreRepository>(
          update: (_, dio, previous) => ApiGenreRepository(dio),
        ),
        ChangeNotifierProvider<GenreListNotifier>(
          create: (context) =>
          GenreListNotifier(context.read<GenreRepository>())..load(),
        ),

        ProxyProvider<Dio, PersonRepository>(
          update: (_, dio, previous) => ApiPersonRepository(dio),
        ),
        ChangeNotifierProvider<PersonListNotifier>(
          create: (context) =>
          PersonListNotifier(context.read<PersonRepository>())..load(),
        ),

        ProxyProvider<Dio, CountryRepository>(
          update: (_, dio, previous) => ApiCountryRepository(dio),
        ),
        ChangeNotifierProvider<CountryListNotifier>(
          create: (context) =>
          CountryListNotifier(context.read<CountryRepository>())..load(),
        ),

        ProxyProvider<Dio, HallRepository>(
          update: (_, dio, previous) => ApiHallRepository(dio),
        ),
        ChangeNotifierProvider<HallListNotifier>(
          create: (context) =>
          HallListNotifier(context.read<HallRepository>())..load(),
        ),

        ProxyProvider<Dio, SessionRepository>(
          update: (_, dio, previous) => ApiSessionRepository(dio),
        ),
        ChangeNotifierProvider<SessionListNotifier>(
          create: (context) =>
          SessionListNotifier(context.read<SessionRepository>())..load(),
        ),

        ProxyProvider<Dio, BookingRepository>(
          update: (_, dio, previous) => ApiBookingRepository(dio),
        ),
        ChangeNotifierProvider<BookingListNotifier>(
          create: (context) =>
          BookingListNotifier(context.read<BookingRepository>())..load(),
        ),

        ProxyProvider<Dio, TicketRepository>(
          update: (_, dio, previous) => ApiTicketRepository(dio),
        ),
        ChangeNotifierProvider<TicketListNotifier>(
          create: (context) =>
          TicketListNotifier(context.read<TicketRepository>())..load(),
        ),

        ChangeNotifierProvider<ReferenceCache>(
          create: (context) => ReferenceCache(
            context.read<CountryRepository>(),
            context.read<GenreRepository>(),
            context.read<HallRepository>(),
            context.read<PersonRepository>(),
          )..load(),
        ),
      ],
      child: MyApp(
        router: router,
        auth: authNotifier,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  final AuthNotifier auth;

  const MyApp({
    super.key,
    required this.router,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      builder: (context, child) {
        return _ActivityDetector(
          auth: auth,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _ActivityDetector extends StatefulWidget {
  final AuthNotifier auth;
  final Widget child;

  const _ActivityDetector({
    required this.auth,
    required this.child,
  });

  @override
  State<_ActivityDetector> createState() => _ActivityDetectorState();
}

class _ActivityDetectorState extends State<_ActivityDetector> {
  bool _warningShown = false;

  void _recordActivity() {
    widget.auth.recordActivity();
  }

  void _showInactivityWarning() {
    if (_warningShown) {
      return;
    }

    if (!widget.auth.consumeInactivityWarning()) {
      return;
    }

    _warningShown = true;

    final dialogContext = rootNavigatorKey.currentContext;

    if (dialogContext == null) {
      _warningShown = false;
      return;
    }

    showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Сессия скоро завершится'),
          content: const Text(
            'Вы давно не проявляли активность.\n\n'
                'Сессия завершится через 30 секунд.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                widget.auth.recordActivity();
                Navigator.of(context).pop();
              },
              child: const Text('Продолжить работу'),
            ),
          ],
        );
      },
    ).then((_) {
      _warningShown = false;
    });
  }

  @override
  void initState() {
    super.initState();

    widget.auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) {
      return;
    }

    final remaining = widget.auth.inactivityRemaining;

    if (remaining == null ||
        remaining > const Duration(seconds: 30) ||
        remaining <= Duration.zero ||
        _warningShown) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _warningShown) {
        return;
      }

      _showInactivityWarning();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (_, _) {
        _recordActivity();
        return KeyEventResult.ignored;
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _recordActivity(),
        onPointerUp: (_) => _recordActivity(),
        onPointerSignal: (_) => _recordActivity(),
        child: widget.child,
      ),
    );
  }
}