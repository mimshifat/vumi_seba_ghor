import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhumi_kajer_hisab/app.dart';

void main() {
  testWidgets('App renders main operational dashboard without exposing money on open', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BhumiKajerHisabApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app title & branding exist
    expect(find.text('রজব ভূমি সেবা ঘর'), findsWidgets);
    expect(find.text('ড্যাশবোর্ড'), findsWidgets);
    expect(find.text('আবেদন'), findsWidgets);
    expect(find.text('হিসাব'), findsWidgets);
    expect(find.text('বিশ্লেষণ'), findsWidgets);
    expect(find.text('মেনু'), findsWidgets);

    // Verify operational work buttons are present on landing
    expect(find.text('নতুন আবেদন'), findsWidgets);
    expect(find.text('নতুন কাজ'), findsWidgets);
    expect(find.text('গ্রাহক খাতা'), findsWidgets);

    // Verify NO cashflow/profit money banner exists on landing dashboard
    expect(find.text('চলতি মাসের আর্থিক হিসাব'), findsNothing);
    expect(find.text('প্রকৃত ব্যবসায়িক লাভ'), findsNothing);
  });
}
