class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле обязательно';
    }

    return null;
  }

  static String? maxLength(String? value, int max) {
    final requiredError = required(value);

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length > max) {
      return 'Максимум $max символов';
    }

    return null;
  }

  static String? integer(String? value, {int? min, int? max}) {
    final requiredError = required(value);

    if (requiredError != null) {
      return requiredError;
    }

    final number = int.tryParse(value!.trim());

    if (number == null) {
      return 'Введите целое число';
    }

    if (min != null && number < min) {
      return 'Число должно быть не меньше $min';
    }

    if (max != null && number > max) {
      return 'Число должно быть не больше $max';
    }

    return null;
  }

  static String? positiveInteger(String? value) {
    return integer(value, min: 1);
  }

  static String? copiesAvailable(String? availableValue, String? totalValue) {
    final requiredError = required(availableValue);

    if (requiredError != null) {
      return requiredError;
    }

    final available = int.tryParse(availableValue!.trim());

    if (available == null) {
      return 'Введите целое число';
    }

    if (available < 0) {
      return 'Число не может быть отрицательным';
    }

    final total = int.tryParse(totalValue?.trim() ?? '');

    if (total == null) {
      return null;
    }

    if (available > total) {
      return 'Доступно не может быть больше общего количества';
    }

    return null;
  }
}
