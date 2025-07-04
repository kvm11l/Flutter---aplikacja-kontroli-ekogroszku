// screens/purchase_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/coal_purchase.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  @override
  void dispose() {
    _supplierController.dispose();
    _amountController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final newPurchase = CoalPurchase(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        supplier: _supplierController.text,
        amount: double.parse(_amountController.text),
        price: double.parse(_priceController.text),
        date: _purchaseDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      try {
        await DatabaseHelper.instance.createPurchase(newPurchase);
        await DatabaseHelper.instance.addToInventory(
          newPurchase.id,
          newPurchase.amount,
        );

        if (!mounted) return;
        Navigator.pop(context, true); // Zwróć true aby odświeżyć
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj zakup ekogroszku'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Dostawca',
                  icon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj nazwę dostawcy';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Ilość (kg)',
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
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Cena (zł)',
                  icon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj cenę zakupu';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Podaj poprawną liczbę';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 16),
                  Text(
                    'Data zakupu: ${_purchaseDate.day}.${_purchaseDate.month}.${_purchaseDate.year}',
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Zmień datę'),
                  ),
                ],
              ),
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
                child: const Text('Zapisz zakup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}