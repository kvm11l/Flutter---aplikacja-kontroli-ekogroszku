import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class InventoryCard extends StatelessWidget {
  final String supplier;
  final double amount;
  final double remaining;
  final DateTime date;

  const InventoryCard({
    super.key,
    required this.supplier,
    required this.amount,
    required this.remaining,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (remaining / amount) * 100;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(supplier, style: AppTextStyles.header),
            const SizedBox(height: 8),
            Text('Zakupiono: ${amount.toStringAsFixed(2)} kg'),
            Text('Pozostało: ${remaining.toStringAsFixed(2)} kg'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: remaining / amount,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            Text('${percentage.toStringAsFixed(1)}% pozostało'),
            const SizedBox(height: 8),
            Text('Data zakupu: ${AppHelpers.formatDate(date)}',
                style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}