import 'package:flutter/material.dart';

import '../logic/calculator.dart';
import '../logic/currency.dart';

class ResultScreen extends StatelessWidget {
  final String title;
  final String expression;
  final Map<String, String> rawQuery;
  final String backPath;

  const ResultScreen({
    super.key,
    required this.title,
    required this.expression,
    required this.rawQuery,
    required this.backPath,
  });

  @override
  Widget build(BuildContext context) {
    if (rawQuery.containsKey('a') && rawQuery.containsKey('op') &&
        rawQuery.containsKey('b')) {
      final result = calculate(rawQuery['a'], rawQuery['op'], rawQuery['b']);

      if (result is CalcFailure) {
        return _errorScreen(context, result.message);
      }

      final value = (result as CalcSuccess).value;

      return _resultScreen(
        context,
        title: title,
        expression: expression,
        result: value.toStringAsFixed(2),
      );
    }

    if (rawQuery.containsKey('from') && rawQuery.containsKey('to') &&
        rawQuery.containsKey('amount')) {
      final from = rawQuery['from'];
      final to = rawQuery['to'];
      final amountString = rawQuery['amount'];

      final amount = double.tryParse(
        amountString?.replaceAll(',', '.') ?? '',
      );

      if (from == null || to == null || amount == null) {
        return _errorScreen(
          context,
          'Некорректные параметры конвертации',
        );
      }

      if (!rates.containsKey(from) || !rates.containsKey(to)) {
        return _errorScreen(
          context,
          'Неизвестная валюта',
        );
      }

      final result = convert(amount, from, to);

      return _resultScreen(
        context,
        title: title,
        expression: '${amount.toStringAsFixed(2)} $from $to',
        result: '${result.toStringAsFixed(2)} $to',
      );
    }

    return _errorScreen(
      context,
      'Не хватает параметров для вычисления',
    );
  }

  Widget _resultScreen(BuildContext context, {
    required String title,
    required String expression,
    required String result,
  }) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                ),
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          expression,
                          style: Theme
                              .of(context)
                              .textTheme
                              .headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        const Text('Результат:'),
                        const SizedBox(height: 8),
                        Text(
                          result,
                          style: Theme
                              .of(context)
                              .textTheme
                              .headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Назад'),
                        ),
                      ],
                    )
                )
            )
        )
    );
  }

  Widget _errorScreen(BuildContext context,
      String message,) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Ошибка'),
        ),
        body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon (
                    Icons.error_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Назад'),
                  )
                ],
              ),
            )
        )
    );
  }
}