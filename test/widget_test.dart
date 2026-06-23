// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_bet_pro/main.dart';

void main() {
  testWidgets('Bankroll Bet Pro Smoke Test', (WidgetTester tester) async {
    // Construimos la app utilizando la clase correcta de tu proyecto
    await tester.pumpWidget(const BankrollBetProApp());

    // Verificamos que el título principal aparezca en pantalla
    expect(find.text('Bankroll '), findsOneWidget);
  });
}