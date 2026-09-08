import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/loan_repository.dart';
import 'repositories/persistent_author_repository.dart';
import 'repositories/persistent_book_repository.dart';
import 'repositories/persistent_genre_repository.dart';
import 'repositories/persistent_loan_repository.dart';
import 'repositories/persistent_publisher_repository.dart';
import 'repositories/persistent_reader_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';

import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/loan_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';

import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  final prefs =
  await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>(
          create: (_) =>
              PersistentBookRepository(prefs),
        ),

        ChangeNotifierProvider<BookListNotifier>(
          create: (context) =>
          BookListNotifier(
            context.read<BookRepository>(),
          )..load(),
        ),

        Provider<AuthorRepository>(
          create: (_) =>
              PersistentAuthorRepository(prefs),
        ),

        ChangeNotifierProvider<AuthorListNotifier>(
          create: (context) =>
          AuthorListNotifier(
            context.read<AuthorRepository>(),
          )..load(),
        ),

        Provider<GenreRepository>(
          create: (_) =>
              PersistentGenreRepository(prefs),
        ),

        ChangeNotifierProvider<GenreListNotifier>(
          create: (context) =>
          GenreListNotifier(
            context.read<GenreRepository>(),
          )..load(),
        ),

        Provider<PublisherRepository>(
          create: (context) =>
              PersistentPublisherRepository(
                prefs,
                context.read<BookRepository>(),
              ),
        ),

        ChangeNotifierProvider<PublisherListNotifier>(
          create: (context) =>
          PublisherListNotifier(
            context.read<PublisherRepository>(),
          )..load(),
        ),

        Provider<ReaderRepository>(
          create: (_) =>
              PersistentReaderRepository(prefs),
        ),

        ChangeNotifierProvider<ReaderListNotifier>(
          create: (context) =>
          ReaderListNotifier(
            context.read<ReaderRepository>(),
          )..load(),
        ),

        Provider<LoanRepository>(
          create: (context) =>
              PersistentLoanRepository(
                prefs,
                context.read<BookRepository>(),
                context.read<ReaderRepository>(),
              ),
        ),

        ChangeNotifierProvider<LoanListNotifier>(
          create: (context) =>
          LoanListNotifier(
            context.read<LoanRepository>(),
          )..load(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
    );
  }
}