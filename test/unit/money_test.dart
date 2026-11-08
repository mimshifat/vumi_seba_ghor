import 'package:flutter_test/flutter_test.dart';
import 'package:bhumi_kajer_hisab/core/utils/money.dart';

void main() {
  group('Money Class Unit Tests', () {
    test('Zero money represents 0 paisa', () {
      expect(Money.zero.paisa, equals(0));
      expect(Money.zero.inTaka, equals(0));
      expect(Money.zero.isZero, isTrue);
    });

    test('Paisa to Taka conversion is exact', () {
      final m = Money.fromTaka(7000);
      expect(m.paisa, equals(700000));
      expect(m.inTaka, equals(7000));
    });

    test('Addition without floating-point error', () {
      final m1 = Money.fromTaka(4000);
      final m2 = Money.fromTaka(3000);
      final total = m1 + m2;
      expect(total.inTaka, equals(7000));
      expect(total.paisa, equals(700000));
    });

    test('Subtraction and Due calculation', () {
      final agreed = Money.fromTaka(7000);
      final received = Money.fromTaka(4000);
      final due = agreed - received;
      expect(due.inTaka, equals(3000));
      expect(due.isPositive, isTrue);
    });

    test('Profit calculation (Agreed - Expenses)', () {
      final agreed = Money.fromTaka(8500);
      final expense = Money.fromTaka(2500);
      final profit = agreed - expense;
      expect(profit.inTaka, equals(6000));
    });

    test('Formatting to Bengali currency string', () {
      final m = Money.fromTaka(7000);
      expect(m.formatBengali(), equals('৳৭,০০০'));

      final mLarge = Money.fromTaka(125000);
      expect(mLarge.formatBengali(), equals('৳১,২৫,০০০'));
    });
  });
}

