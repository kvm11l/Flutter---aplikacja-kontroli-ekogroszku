import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../widgets/inventory_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stan magazynu'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getCurrentInventory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Magazyn jest pusty'));
          }

          final inventory = snapshot.data!;
          return ListView.builder(
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final item = inventory[index];
              return InventoryCard(
                supplier: item['supplier'],
                amount: item['amount'],
                remaining: item['remaining_amount'],
                date: DateTime.fromMillisecondsSinceEpoch(item['date']),
              );
            },
          );
        },
      ),
    );
  }
}