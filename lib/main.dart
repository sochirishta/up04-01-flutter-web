import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/loan_repository.dart';
import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_loan_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_reader_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';

import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/loan_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';
import 'state/reference_cache.dart';

import 'core/api_client.dart';

import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>(create: (_) => buildDio()),

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

        ChangeNotifierProvider(
          create: (context) => ReferenceCache(
            context.read<AuthorRepository>(),
            context.read<GenreRepository>(),
            context.read<PublisherRepository>(),
          ),
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
    return MaterialApp.router(routerConfig: appRouter);
  }
}
