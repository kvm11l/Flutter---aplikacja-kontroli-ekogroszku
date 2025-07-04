// models/coal_purchase.dart
class CoalPurchase {
  final String id;
  final String supplier;
  final double amount;
  final double price;
  final DateTime date;
  final String? notes;

  CoalPurchase({
    required this.id,
    required this.supplier,
    required this.amount,
    required this.price,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier': supplier,
      'amount': amount,
      'price': price,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory CoalPurchase.fromMap(Map<String, dynamic> map) {
    return CoalPurchase(
      id: map['id'],
      supplier: map['supplier'],
      amount: map['amount'],
      price: map['price'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      notes: map['notes'],
    );
  }
}