import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/purchase_screen.dart';
import 'screens/usage_screen.dart';
import 'screens/history_screen.dart';
import 'screens/reports_screen.dart';

void main() {
  runApp(const EcoCoalApp());
}

class EcoCoalApp extends StatelessWidget {
  const EcoCoalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kontrola Ekogroszku',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
      routes: {
        '/purchase': (context) => const PurchaseScreen(),
        '/usage': (context) => const UsageScreen(),
        '/history': (context) => const HistoryScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
    );
  }
}