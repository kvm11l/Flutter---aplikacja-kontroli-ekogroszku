import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/coal_purchase.dart';
import '../widgets/purchase_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _purchasesWithInventoryFuture;
  String _sortBy = 'data_malejąco';
  final Map<String, String> _sortOptions = {
    'data_rosnąco': 'Data (rosnąco)',
    'data_malejąco': 'Data (malejąco)',
    'ilość_rosnąco': 'Ilość (rosnąco)',
    'ilość_malejąco': 'Ilość (malejąco)',
    'cena_rosnąco': 'Cena (rosnąco)',
    'cena_malejąco': 'Cena (malejąco)',
    'pozostało_rosnąco': 'Pozostało (rosnąco)',
    'pozostało_malejąco': 'Pozostało (malejąco)',
  };

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _purchasesWithInventoryFuture = _getPurchasesWithInventory();
    });
  }

  Future<List<Map<String, dynamic>>> _getPurchasesWithInventory() async {
    final db = await DatabaseHelper.instance.database;
    final purchases = await db.rawQuery('''
      SELECT p.*, i.remaining_amount
      FROM purchases p
      LEFT JOIN inventory i ON p.id = i.purchase_id
    ''');

    // Tworzymy kopię listy przed sortowaniem
    final purchasesCopy = List<Map<String, dynamic>>.from(purchases);
    return _sortPurchases(purchasesCopy);
  }

  List<Map<String, dynamic>> _sortPurchases(List<Map<String, dynamic>> purchases) {
    // Tworzymy kopię listy przed sortowaniem
    final sortedPurchases = List<Map<String, dynamic>>.from(purchases);

    switch (_sortBy) {
      case 'data_rosnąco':
        sortedPurchases.sort((a, b) => (DateTime.fromMillisecondsSinceEpoch(a['date']))
            .compareTo(DateTime.fromMillisecondsSinceEpoch(b['date'])));
        break;
      case 'data_malejąco':
        sortedPurchases.sort((a, b) => (DateTime.fromMillisecondsSinceEpoch(b['date']))
            .compareTo(DateTime.fromMillisecondsSinceEpoch(a['date'])));
        break;
      case 'ilość_rosnąco':
        sortedPurchases.sort((a, b) => (a['amount'] as double).compareTo(b['amount'] as double));
        break;
      case 'ilość_malejąco':
        sortedPurchases.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
        break;
      case 'cena_rosnąco':
        sortedPurchases.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
        break;
      case 'cena_malejąco':
        sortedPurchases.sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
        break;
      case 'pozostało_rosnąco':
        sortedPurchases.sort((a, b) =>
            (a['remaining_amount'] ?? 0.0).compareTo(b['remaining_amount'] ?? 0.0));
        break;
      case 'pozostało_malejąco':
        sortedPurchases.sort((a, b) =>
            (b['remaining_amount'] ?? 0.0).compareTo(a['remaining_amount'] ?? 0.0));
        break;
    }
    return sortedPurchases;
  }

  Future<void> _showSortDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sortuj zakupy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sortOptions.entries
              .map((entry) => RadioListTile<String>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: _sortBy,
            onChanged: (value) {
              Navigator.pop(context, value);
            },
          ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _sortBy = result;
        _loadPurchases();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia zakupów'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(context),
            tooltip: 'Sortuj',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPurchases,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _purchasesWithInventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak historii zakupów'));
          }

          final purchases = snapshot.data!;
          return ListView.builder(
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              return PurchaseItem(
                purchase: CoalPurchase.fromMap(purchase),
                remainingAmount: purchase['remaining_amount'] ?? 0.0,
              );
            },
          );
        },
      ),
    );
  }
}