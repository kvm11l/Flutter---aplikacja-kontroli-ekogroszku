import 'package:flutter/material.dart';
import '../models/coal_purchase.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/purchase_details_screen.dart';
import '../screens/purchase_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/usage_screen.dart';


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
      // app/eco_coal_app.dart
      routes: {
        '/purchase': (context) => const PurchaseScreen(),
        '/usage': (context) => const UsageScreen(),
        '/history': (context) => const HistoryScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/purchase-details': (context) {
          final purchase = ModalRoute.of(context)!.settings.arguments as CoalPurchase;
          return PurchaseDetailsScreen(purchase: purchase);
        },
      },
    );
  }
}