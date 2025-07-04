import 'package:flutter/material.dart';
import '../models/coal_purchase.dart';
import '../screens/purchase_details_screen.dart';

class PurchaseItem extends StatelessWidget {
  final CoalPurchase purchase;
  final double remainingAmount;

  const PurchaseItem({
    super.key,
    required this.purchase,
    required this.remainingAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(purchase.supplier),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${purchase.amount} kg • ${purchase.price} zł'),
            Text('${_formatDate(purchase.date)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Pozostało: ${remainingAmount.toStringAsFixed(2)} kg'),
                const SizedBox(width: 10),
                Expanded(
                  child: LinearProgressIndicator(
                    value: remainingAmount / purchase.amount,
                    backgroundColor: Colors.grey[200],
                    color: _getProgressColor(remainingAmount, purchase.amount),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PurchaseDetailsScreen(purchase: purchase),
            ),
          );
        },
      ),
    );
  }

  Color _getProgressColor(double remaining, double total) {
    final percentage = remaining / total;
    if (percentage < 0.2) return Colors.red;
    if (percentage < 0.5) return Colors.orange;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}