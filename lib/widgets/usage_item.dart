import 'package:flutter/material.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class UsageItem extends StatelessWidget {
  final double amount;
  final int days;
  final double temperature;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback? onTap;

  const UsageItem({
    super.key,
    required this.amount,
    required this.days,
    required this.temperature,
    required this.startDate,
    required this.endDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dailyUsage = AppHelpers.calculateDailyUsage(amount, days);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text('${amount.toStringAsFixed(2)} kg przez $days dni'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${dailyUsage.toStringAsFixed(2)} kg/dzień'),
            Text('Śr. temp: ${temperature.toStringAsFixed(1)}°C'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppHelpers.formatDate(startDate)),
            Text(AppHelpers.formatDate(endDate)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}