import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  bool get _passwordHasMinLength => _passwordController.text.length >= 8;

  bool get _passwordHasDigit =>
      RegExp(r'\d').hasMatch(_passwordController.text);

  bool get _passwordHasSpecial =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]+=;''`~]').hasMatch(
        _passwordController.text,
      );

  bool get _passwordIsValid =>
      _passwordHasMinLength && _passwordHasDigit && _passwordHasSpecial;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String _) {
    setState(() {});
  }

  Widget _passwordRequirement({
    required bool satisfied,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: satisfied
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: satisfied
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final user = await context.read<AuthNotifier>().register(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Регистрация выполнена. Пользователь ${user.username} создан.',
          ),
        ),
      );

      context.go('/login');
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось выполнить регистрацию.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Регистрация',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _usernameController,
                        enabled: !_loading,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Логин',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final username = value?.trim() ?? '';

                          if (username.isEmpty) {
                            return 'Введите логин';
                          }

                          if (username.length < 3) {
                            return 'Минимум 3 символа';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameController,
                        enabled: !_loading,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'ФИО',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите ФИО';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_loading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Введите email';
                          }

                          if (!email.contains('@')) {
                            return 'Введите корректный email';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_loading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onChanged: _onPasswordChanged,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: _loading
                                ? null
                                : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final password = value ?? '';

                          if (password.isEmpty) {
                            return 'Введите пароль';
                          }

                          if (password.length < 8) {
                            return 'Минимум 8 символов';
                          }

                          if (!RegExp(r'\d').hasMatch(password)) {
                            return 'Пароль должен содержать цифру';
                          }

                          if (!RegExp(
                            r'[!@#$%^&*(),.?":{}|<>_\-\\/$begin:math:display$$end:math:display$+=;''`~]',
                          ).hasMatch(password)) {
                            return 'Пароль должен содержать спецсимвол';
                          }

                          return null;
                        },
                      ),
                      if (_passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _passwordRequirement(
                          satisfied: _passwordHasMinLength,
                          text: 'Минимум 8 символов',
                        ),
                        _passwordRequirement(
                          satisfied: _passwordHasDigit,
                          text: 'Хотя бы одна цифра',
                        ),
                        _passwordRequirement(
                          satisfied: _passwordHasSpecial,
                          text: 'Хотя бы один специальный символ',
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loading || !_passwordIsValid
                            ? null
                            : _submit,
                        child: _loading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('Зарегистрироваться'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading ? null : () => context.go('/login'),
                        child: const Text('Уже есть аккаунт? Войти'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}