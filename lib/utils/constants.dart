import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.orange;
  static const Color secondary = Colors.deepOrange;
  static const Color background = Color(0xFFF5F5F5);
}

class AppTextStyles {
  static const TextStyle header = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: Colors.black54,
  );
}

class AppStrings {
  static const String appName = 'Kontrola Ekogroszku';
  static const String emptyInventory = 'Brak ekogroszku w magazynie';
}