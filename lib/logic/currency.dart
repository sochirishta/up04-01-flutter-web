const rates = {
  'USD': 1.0,
  'EUR': 0.85,
  'RUB': 80.0,
  'GBP': 0.74,
  'JPY': 147.0
};

double convert(double amount, String from, String to) {
  final fromRate = rates[from]!;
  final toRate = rates[to]!;

  return amount * toRate / fromRate;
}