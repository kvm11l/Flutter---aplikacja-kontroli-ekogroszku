// screens/usage_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/coal_usage.dart';

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _daysController = TextEditingController();
  final _tempController = TextEditingController();
  final _weatherController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _inventory = [];
  String? _selectedPurchaseId;
  double _selectedPurchaseAmount = 0;
  final List<String> _availablePurposes = [
    'Woda użytkowa',
    'Grzejniki',
    'Ogrzewanie podłogowe',
    'Basen',
    'Sauna'
  ];
  final List<String> _selectedPurposes = [];
  final TextEditingController _customPurposeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _daysController.dispose();
    _tempController.dispose();
    _weatherController.dispose();
    _notesController.dispose();
    _customPurposeController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    final inventory = await DatabaseHelper.instance.getCurrentInventory();
    setState(() {
      _inventory = inventory;
      if (_inventory.isNotEmpty) {
        _selectedPurchaseId = _inventory.first['id'];
        _selectedPurchaseAmount = _inventory.first['remaining_amount'];
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _updateEndDateBasedOnDays() {
    if (_daysController.text.isNotEmpty) {
      final days = int.tryParse(_daysController.text) ?? 0;
      setState(() {
        _endDate = _startDate.add(Duration(days: days));
      });
    }
  }

  void _addCustomPurpose() {
    if (_customPurposeController.text.isNotEmpty) {
      setState(() {
        _selectedPurposes.add(_customPurposeController.text);
        _customPurposeController.clear();
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() &&
        _selectedPurposes.isNotEmpty &&
        _selectedPurchaseId != null) {
      final amount = double.parse(_amountController.text);


      if (amount > _selectedPurchaseAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie ma tyle ekogroszku w magazynie!')),
        );
        return;
      }else if (_selectedPurposes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wybierz przynajmniej jedno przeznaczenie ciepła')),
        );
      }

      final newUsage = CoalUsage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        daysLasted: int.parse(_daysController.text),
        averageTemperature: double.parse(_tempController.text),
        weatherConditions: _weatherController.text,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        purchaseId: _selectedPurchaseId!,
        heatPurposes: _selectedPurposes
      );

      try {
        // Zapisz użycie
        await DatabaseHelper.instance.createUsage(newUsage);

        // Zaktualizuj magazyn
        final newAmount = _selectedPurchaseAmount - amount;
        await DatabaseHelper.instance.updateInventory(
          _selectedPurchaseId!,
          newAmount,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dane spalania zostały zapisane')),
        );

        // Zwróć true jako potwierdzenie aktualizacji
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd podczas zapisywania: ${e.toString()}')),
        );
      }
      if (_selectedPurposes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wybierz przynajmniej jedno przeznaczenie ciepła')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejestracja spalania'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_inventory.isEmpty)
                const Text(
                  'Brak ekogroszku w magazynie! Najpierw dodaj zakup.',
                  style: TextStyle(color: Colors.red),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wybierz partię ekogroszku:'),
                    DropdownButtonFormField<String>(
                      value: _selectedPurchaseId,
                      items: _inventory.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(
                            '${item['supplier']} (${item['remaining_amount']}kg) - '
                                '${DateTime.fromMillisecondsSinceEpoch(item['date']).day}.'
                                '${DateTime.fromMillisecondsSinceEpoch(item['date']).month}.'
                                '${DateTime.fromMillisecondsSinceEpoch(item['date']).year}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPurchaseId = value;
                          final selected = _inventory.firstWhere(
                                  (item) => item['id'] == value);
                          _selectedPurchaseAmount = selected['remaining_amount'];
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Wybierz partię ekogroszku';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Ilość ekogroszku (kg)',
                  icon: Icon(Icons.scale),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj ilość ekogroszku';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Podaj poprawną liczbę';
                  }
                  if (_selectedPurchaseId != null &&
                      double.parse(value) > _selectedPurchaseAmount) {
                    return 'Masz tylko $_selectedPurchaseAmount kg tej partii';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.isNotEmpty && _daysController.text.isNotEmpty) {
                    setState(() {
                      _updateEndDateBasedOnDays();
                    });
                  }
                },
              ),
              TextFormField(
                controller: _daysController,
                decoration: const InputDecoration(
                  labelText: 'Ilość dni',
                  icon: Icon(Icons.calendar_view_day),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj ilość dni';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Podaj poprawną liczbę';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.isNotEmpty && _amountController.text.isNotEmpty) {
                    setState(() {
                      _updateEndDateBasedOnDays();
                    });
                  }
                },
              ),
              TextFormField(
                controller: _tempController,
                decoration: const InputDecoration(
                  labelText: 'Średnia temperatura (°C)',
                  icon: Icon(Icons.thermostat),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj średnią temperaturę';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Podaj poprawną liczbę';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _weatherController,
                decoration: const InputDecoration(
                  labelText: 'Warunki pogodowe',
                  icon: Icon(Icons.cloud),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Opisz warunki pogodowe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data rozpoczęcia: ${_startDate.day}.${_startDate.month}.${_startDate.year}',
                      ),
                      TextButton(
                        onPressed: () => _selectDate(context, true),
                        child: const Text('Zmień datę'),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data zakończenia: ${_endDate.day}.${_endDate.month}.${_endDate.year}',
                      ),
                      TextButton(
                        onPressed: () => _selectDate(context, false),
                        child: const Text('Zmień datę'),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                'Średnie dzienne zużycie: ${_amountController.text.isNotEmpty && _daysController.text.isNotEmpty ? (double.tryParse(_amountController.text) ?? 0) / (int.tryParse(_daysController.text) ?? 1) : 0.0} kg/dzień',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text('Przeznaczenie ciepła:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _availablePurposes.map((purpose) {
                  return FilterChip(
                    label: Text(purpose),
                    selected: _selectedPurposes.contains(purpose),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPurposes.add(purpose);
                        } else {
                          _selectedPurposes.remove(purpose);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customPurposeController,
                      decoration: const InputDecoration(
                        labelText: 'Inne przeznaczenie',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addCustomPurpose,
                  ),
                ],
              ),
              if (_selectedPurposes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _selectedPurposes.map((purpose) {
                    return Chip(
                      label: Text(purpose),
                      onDeleted: () {
                        setState(() {
                          _selectedPurposes.remove(purpose);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Uwagi (opcjonalne)',
                  icon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Zapisz dane spalania'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}