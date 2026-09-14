import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/auth_api.dart';

import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_loan_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_reader_repository.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/loan_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';

import 'state/author_list_notifier.dart';
import 'state/auth_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/loan_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';
import 'state/reference_cache.dart';

import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  final authDio = buildDio();
  final authApi = AuthApi(authDio);

  final authNotifier = AuthNotifier(prefs, authApi);

  await authNotifier.restore();

  final dio = buildDio(
    tokenProvider: () => authNotifier.accessToken,
    refreshToken: authNotifier.refreshTokens,
  );

  final router = buildRouter(authNotifier);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        Provider<Dio>.value(value: dio),
        ProxyProvider<Dio, BookRepository>(
          update: (_, dio, previous) => ApiBookRepository(dio),
        ),
        ChangeNotifierProvider<BookListNotifier>(
          create: (context) =>
              BookListNotifier(context.read<BookRepository>())..load(),
        ),
        ProxyProvider<Dio, AuthorRepository>(
          update: (_, dio, previous) => ApiAuthorRepository(dio),
        ),
        ChangeNotifierProvider<AuthorListNotifier>(
          create: (context) =>
              AuthorListNotifier(context.read<AuthorRepository>())..load(),
        ),
        ProxyProvider<Dio, GenreRepository>(
          update: (_, dio, previous) => ApiGenreRepository(dio),
        ),
        ChangeNotifierProvider<GenreListNotifier>(
          create: (context) =>
              GenreListNotifier(context.read<GenreRepository>())..load(),
        ),
        ProxyProvider<Dio, PublisherRepository>(
          update: (_, dio, previous) => ApiPublisherRepository(dio),
        ),
        ChangeNotifierProvider<PublisherListNotifier>(
          create: (context) =>
              PublisherListNotifier(context.read<PublisherRepository>())
                ..load(),
        ),
        ProxyProvider<Dio, ReaderRepository>(
          update: (_, dio, previous) => ApiReaderRepository(dio),
        ),
        ChangeNotifierProvider<ReaderListNotifier>(
          create: (context) =>
              ReaderListNotifier(context.read<ReaderRepository>())..load(),
        ),
        ProxyProvider<Dio, LoanRepository>(
          update: (_, dio, previous) => ApiLoanRepository(dio),
        ),
        ChangeNotifierProvider<LoanListNotifier>(
          create: (context) =>
              LoanListNotifier(context.read<LoanRepository>())..load(),
        ),
        ChangeNotifierProvider<ReferenceCache>(
          create: (context) => ReferenceCache(
            context.read<AuthorRepository>(),
            context.read<GenreRepository>(),
            context.read<PublisherRepository>(),
          ),
        ),
      ],
      child: MyApp(router: router, auth: authNotifier),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  final AuthNotifier auth;

  const MyApp({super.key, required this.router, required this.auth});

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

  const _ActivityDetector({required this.auth, required this.child});

  @override
  State<_ActivityDetector> createState() => _ActivityDetectorState();
}

class _ActivityDetectorState extends State<_ActivityDetector> {
  bool _warningShown = false;

  void _recordActivity() {
    widget.auth.recordActivity();
  }

  void _showInactivityWarning() {
    if (_warningShown || !widget.auth.isInactivityWarning) {
      return;
    }

    _warningShown = true;

    showDialog<void>(
      context: rootNavigatorKey.currentContext!,
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

    if (!widget.auth.isInactivityWarning || _warningShown) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.auth.isInactivityWarning || _warningShown) {
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
