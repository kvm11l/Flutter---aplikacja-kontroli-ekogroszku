import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../app/eco_coal_app.dart';
import '../screens/home_screen.dart';

void main() {
  testWidgets('Test ładowania ekranu głównego', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoCoalApp());
    expect(find.text('Kontrola Ekogroszku'), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}