import 'package:flutter_test/flutter_test.dart';
import 'package:up04_01_flutter_web/logic/calculator.dart';

void main() {
  test('сложение', () {
    final result = calculate('2', '+', '3');
    expect((result as CalcSuccess).value, 5);
  });

  test('вычитание', () {
    final result = calculate('5', '-', '3');
    expect((result as CalcSuccess).value, 2);
  });

  test('умножение', () {
    final result = calculate('5', '*', '5');
    expect((result as CalcSuccess).value, 25);
  });

  test('деление', () {
    final result = calculate('10', '/', '2');
    expect((result as CalcSuccess).value, 5);
  });

  test('деление на ноль', () {
    final result = calculate('10', '/', '0');
    expect(result, isA<CalcFailure>());
  });

  test('некорректное число', () {
    final result = calculate('abc', '+', '0');
    expect(result, isA<CalcFailure>());
  });
}