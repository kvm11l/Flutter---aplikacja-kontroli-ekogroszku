import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/coal_purchase.dart';
import '../widgets/usage_item.dart';
import '../widgets/note_item.dart';

class PurchaseDetailsScreen extends StatefulWidget {
  final CoalPurchase purchase;

  const PurchaseDetailsScreen({super.key, required this.purchase});

  @override
  State<PurchaseDetailsScreen> createState() => _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends State<PurchaseDetailsScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;
  final TextEditingController _noteController = TextEditingController();
  final Map<String, TextEditingController> _editNoteControllers = {};

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() {
    setState(() {
      _detailsFuture = _getPurchaseDetails(widget.purchase.id);
    });
  }

  Future<Map<String, dynamic>> _getPurchaseDetails(String purchaseId) async {
    final db = await DatabaseHelper.instance.database;

    final inventory = await db.query(
      'inventory',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    final remaining = inventory.isNotEmpty ? inventory.first['remaining_amount'] as double : 0.0;

    final usages = await db.rawQuery('''
      SELECT amount, days_lasted as days, average_temperature as temp, 
             start_date, end_date
      FROM usages
      WHERE purchase_id = ?
      ORDER BY start_date DESC
    ''', [purchaseId]);

    final notes = await db.rawQuery('''
      SELECT id, content, created_at
      FROM purchase_notes
      WHERE purchase_id = ?
      ORDER BY created_at DESC
    ''', [purchaseId]);

    // Inicjalizuj kontrolery do edycji
    for (final note in notes) {
      final noteId = note['id'].toString();
      final content = note['content'] as String? ?? '';
      if (!_editNoteControllers.containsKey(noteId)) {
        _editNoteControllers[noteId] = TextEditingController(text: content);
      }
    }

    return {
      'remaining': remaining,
      'usages': usages,
      'notes': notes,
    };
  }

  Future<void> _addNote() async {
    if (_noteController.text.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    await db.insert('purchase_notes', {
      'purchase_id': widget.purchase.id,
      'content': _noteController.text,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    _noteController.clear();
    _loadDetails();
  }

  Future<void> _deleteNote(String noteId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'purchase_notes',
      where: 'id = ?',
      whereArgs: [int.parse(noteId)],
    );
    _editNoteControllers.remove(noteId);
    _loadDetails();
  }

  Future<void> _updateNote(String noteId, String newContent) async {
    if (newContent.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    await db.update(
      'purchase_notes',
      {'content': newContent},
      where: 'id = ?',
      whereArgs: [int.parse(noteId)],
    );
    _loadDetails();
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final controller in _editNoteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Szczegóły zakupu: ${widget.purchase.supplier}'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final remaining = data['remaining'] as double;
          final usages = data['usages'] as List<Map<String, dynamic>>;
          final notes = data['notes'] as List<Map<String, dynamic>>;

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Dostawca: ${widget.purchase.supplier}',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Ilość: ${widget.purchase.amount} kg'),
                      Text('Cena: ${widget.purchase.price} zł'),
                      Text('Data zakupu: ${_formatDate(widget.purchase.date)}'),
                      const SizedBox(height: 16),
                      Text('Pozostało: ${remaining.toStringAsFixed(2)} kg',
                          style: TextStyle(
                              fontSize: 16,
                              color: remaining < 50 ? Colors.red : Colors.green)),
                      LinearProgressIndicator(
                        value: remaining / widget.purchase.amount,
                        backgroundColor: Colors.grey[200],
                      ),
                    ],
                  ),
                ),
              ),

              // Sekcja notatek
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Notatki:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Dodaj nową notatkę...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _addNote,
                        ),
                      ),
                    ),
                    ...notes.map((note) {
                      final noteId = note['id'].toString();
                      return NoteItem(
                        content: note['content'] as String,
                        date: DateTime.fromMillisecondsSinceEpoch(note['created_at'] as int),
                        onDelete: () => _deleteNote(noteId),
                        onEdit: (newContent) => _updateNote(noteId, newContent),
                        editController: _editNoteControllers[noteId]!,
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Sekcja historii pobrań
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Historia pobrań:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: usages.isEmpty
                    ? const Center(child: Text('Brak historii pobrań'))
                    : ListView.builder(
                  itemCount: usages.length,
                  itemBuilder: (context, index) {
                    final usage = usages[index];
                    return UsageItem(
                      amount: usage['amount'] as double,
                      days: usage['days'] as int,
                      temperature: usage['temp'] as double,
                      startDate: DateTime.fromMillisecondsSinceEpoch(usage['start_date'] as int),
                      endDate: DateTime.fromMillisecondsSinceEpoch(usage['end_date'] as int),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}