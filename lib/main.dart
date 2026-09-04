import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'router.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>(
          create: (_) => InMemoryBookRepository(),
        ),
        ChangeNotifierProvider<BookListNotifier>(
          create: (context) => BookListNotifier(
            context.read<BookRepository>(),
          )..load(),
        ),
        Provider<AuthorRepository>(
          create: (_) => InMemoryAuthorRepository(),
        ),
        ChangeNotifierProvider<AuthorListNotifier>(
          create: (context) => AuthorListNotifier(
            context.read<AuthorRepository>(),
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