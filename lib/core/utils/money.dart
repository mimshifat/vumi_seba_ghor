import 'package:intl/intl.dart';
import 'bengali_digits.dart';

class Money implements Comparable<Money> {
  /// Internal storage in Paisa (1 Taka = 100 Paisa)
  /// Guaranteed integer safety - no float rounding errors
  final int paisa;

  const Money._(this.paisa);

  static const Money zero = Money._(0);

  factory Money.fromPaisa(int paisa) => Money._(paisa);

  factory Money.fromTaka(num taka) {
    return Money._((taka * 100).round());
  }

  factory Money.parse(String value) {
    if (value.trim().isEmpty) return Money.zero;
    final english = BengaliDigits.toEnglish(value.replaceAll('৳', '').replaceAll(',', '').trim());
    final parsed = double.tryParse(english) ?? 0.0;
    return Money.fromTaka(parsed);
  }

  int get inTaka => paisa ~/ 100;
  double get inTakaDouble => paisa / 100.0;

  bool get isZero => paisa == 0;
  bool get isPositive => paisa > 0;
  bool get isNegative => paisa < 0;

  Money operator +(Money other) => Money._(paisa + other.paisa);
  Money operator -(Money other) => Money._(paisa - other.paisa);
  Money operator *(num factor) => Money._((paisa * factor).round());

  bool operator <(Money other) => paisa < other.paisa;
  bool operator <=(Money other) => paisa <= other.paisa;
  bool operator >(Money other) => paisa > other.paisa;
  bool operator >=(Money other) => paisa >= other.paisa;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Money && other.paisa == paisa);

  @override
  int get hashCode => paisa.hashCode;

  @override
  int compareTo(Money other) => paisa.compareTo(other.paisa);

  /// Returns standard formatted string like "৳৭,০০০" or "৳১২,৫০০"
  String formatBengali({bool includeSymbol = true}) {
    final absTaka = inTaka.abs();
    final formatter = NumberFormat('#,##,###', 'en_US');
    final formattedNumber = formatter.format(absTaka);
    final bnNumber = BengaliDigits.toBengali(formattedNumber);
    final prefix = paisa < 0 ? '-' : '';
    final symbol = includeSymbol ? '৳' : '';
    return '$prefix$symbol$bnNumber';
  }

  String formatEnglish({bool includeSymbol = true}) {
    final absTaka = inTaka.abs();
    final formatter = NumberFormat('#,##,###', 'en_US');
    final formattedNumber = formatter.format(absTaka);
    final prefix = paisa < 0 ? '-' : '';
    final symbol = includeSymbol ? '৳' : '';
    return '$prefix$symbol$formattedNumber';
  }

  @override
  String toString() => formatBengali();
}

