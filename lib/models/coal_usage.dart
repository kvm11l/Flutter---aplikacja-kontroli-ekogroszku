// models/coal_usage.dart
class CoalUsage {
  final String id;
  final double? amount;
  final int? daysLasted;
  final double? averageTemperature;
  final String? weatherConditions;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final String? purchaseId;
  final String? supplierName;
  final List<String>? heatPurposes;

  CoalUsage({
    required this.id,
    this.amount,
    this.daysLasted,
    this.averageTemperature,
    this.weatherConditions,
    this.startDate,
    this.endDate,
    this.notes,
    this.purchaseId,
    this.supplierName,
    this.heatPurposes,
  });

  double get dailyUsage {
    if (daysLasted == null || amount == null || daysLasted! <= 0) return 0.0;
    return amount! / daysLasted!;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'days_lasted': daysLasted,
      'average_temperature': averageTemperature,
      'weather_conditions': weatherConditions,
      'start_date': startDate?.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'notes': notes,
      'purchase_id': purchaseId,
      'heat_purposes': heatPurposes?.join(','),
    };
  }

  factory CoalUsage.fromMap(Map<String, dynamic> map) {
    return CoalUsage(
      id: map['id'] as String,
      amount: map['amount']?.toDouble(),
      daysLasted: map['days_lasted']?.toInt(),
      averageTemperature: map['average_temperature']?.toDouble(),
      weatherConditions: map['weather_conditions'] as String?,
      startDate: map['start_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int)
          : null,
      notes: map['notes'] as String?,
      purchaseId: map['purchase_id'] as String?,
      heatPurposes: map['heat_purposes']?.toString().split(','),
    );
  }
}