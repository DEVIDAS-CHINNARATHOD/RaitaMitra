import 'package:raitha_mitra/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raitha_mitra/data/models.dart';
import 'package:raitha_mitra/data/repository.dart';
import 'package:raitha_mitra/screens/onboarding.dart';
import 'package:raitha_mitra/state.dart';
import 'package:raitha_mitra/ui/theme.dart';

void main() {
  test('source date and variety survive price parsing', () {
    final p = Price({
      'market_id': 'm',
      'commodity_id': 'c',
      'commodity_name': 'Tomato',
      'variety': 'Local',
      'grade': 'FAQ',
      'modal_price': '1200',
      'report_date': '2006-03-24',
    });
    expect(p.date, DateTime(2006, 3, 24));
    expect(p.variety, 'Local');
    expect(p.modal, 1200);
    expect(p.old, isTrue);
    expect(p.change, isNull);
  });
  testWidgets('welcome separates Google sign-in from local exploration', (
    tester,
  ) async {
    final state = AppState(Repository(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: WelcomeScreen(state: state),
      ),
    );
    expect(find.text('Continue with Google'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Explore on this device'), 160);
    expect(find.text('Explore on this device'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Ask Mitra is a rounded support action and profile is in nav', (
    tester,
  ) async {
    final state = AppState(Repository(null))
      ..ready = true
      ..entered = true
      ..onboarded = true;
    await tester.pumpWidget(RaithaMitraApp(state: state));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Profile'), findsOneWidget);
    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();
    expect(find.text('Ask Mitra'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Ask Mitra stays visible during app startup', (tester) async {
    final state = AppState(Repository(null));
    await tester.pumpWidget(RaithaMitraApp(state: state));
    await tester.pump();
    expect(find.text('Ask Mitra'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
