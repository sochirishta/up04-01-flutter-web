import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  static const _currencies = ['USD', 'EUR', 'RUB', 'GBP', 'JPY'];

  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();

    final savedForm = prefs.getString('from_currency');
    final savedTo = prefs.getString('to_currency');

    if (!mounted) return;

    setState(() {
      if (savedForm != null && _currencies.contains(savedForm)) {
        _fromCurrency = savedForm;
      }

      if (savedTo != null && _currencies.contains(savedTo)) {
        _toCurrency = savedTo;
      }
    });
  }

  Future<void> _saveCurrencies() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'from_currency',
      _fromCurrency,
    );

    await prefs.setString(
        'to_currency',
        _toCurrency
    );
  }

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите сумму';
    }

    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    if (number == null) {
      return 'Введите число';
    }

    if (number < 0) {
      return 'Сумма не может быть отрицательной';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _saveCurrencies();

    final amount = _amountController.text
        .trim()
        .replaceAll(',', '.');

    if (!mounted) return;

    context.go(
      '/converter/result?from=$_fromCurrency&to=$_toCurrency&amount=$amount',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Конвертер валют')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _fromCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Из валюты',
                      border: OutlineInputBorder(),
                    ),
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _fromCurrency = value;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: _toCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Из валюты',
                      border: OutlineInputBorder(),
                    ),
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _toCurrency = value;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Сумма',
                      border: OutlineInputBorder(),
                    ),
                    validator: _amountValidator,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('конвертировать'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
