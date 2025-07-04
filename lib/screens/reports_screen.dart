// screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/coal_usage.dart';
import '../models/coal_purchase.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<CoalUsage>> _usagesFuture;
  List<CoalUsage> _usages = [];
  String _sortBy = 'data_rosnąco'; // Domyślne sortowanie
  final Map<String, String> _sortOptions = {
    'data_rosnąco': 'Data (rosnąco)',
    'data_malejąco': 'Data (malejąco)',
    'ilość_rosnąco': 'Ilość (rosnąco)',
    'ilość_malejąco': 'Ilość (malejąco)',
    'dni_rosnąco': 'Dni (rosnąco)',
    'dni_malejąco': 'Dni (malejąco)',
  };

  @override
  void initState() {
    super.initState();
    _usagesFuture = _loadUsages();
  }

  Future<List<CoalUsage>> _loadUsages() async {
    final usages = await DatabaseHelper.instance.getAllUsages();
    _usages = _sortUsages(usages); // Sortuj przy ładowaniu
    return _usages;
  }

  List<CoalUsage> _sortUsages(List<CoalUsage> usages) {
    switch (_sortBy) {
      case 'data_rosnąco':
        usages.sort((a, b) => (a.startDate ?? DateTime.now())
            .compareTo(b.startDate ?? DateTime.now()));
        break;
      case 'data_malejąco':
        usages.sort((a, b) => (b.startDate ?? DateTime.now())
            .compareTo(a.startDate ?? DateTime.now()));
        break;
      case 'ilość_rosnąco':
        usages.sort((a, b) => (a.amount ?? 0).compareTo(b.amount ?? 0));
        break;
      case 'ilość_malejąco':
        usages.sort((a, b) => (b.amount ?? 0).compareTo(a.amount ?? 0));
        break;
      case 'dni_rosnąco':
        usages.sort((a, b) => (a.daysLasted ?? 0).compareTo(b.daysLasted ?? 0));
        break;
      case 'dni_malejąco':
        usages.sort((a, b) => (b.daysLasted ?? 0).compareTo(a.daysLasted ?? 0));
        break;
    }
    return usages;
  }

  Future<void> _refreshData() async {
    setState(() {
      _usagesFuture = _loadUsages();
    });
  }

  Future<void> _showSortDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sortuj raporty'),
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
        _usages = _sortUsages(_usages);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporty spalania'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(context),
            tooltip: 'Sortuj',
          ),
        ],
      ),
      body: FutureBuilder<List<CoalUsage>>(
        future: _usagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak danych do wyświetlenia'));
          }

          final totalUsed = _usages.fold<double>(
              0, (sum, usage) => sum + (usage.amount ?? 0));
          final averageUsage = _usages.fold<double>(
              0, (sum, usage) => sum + usage.dailyUsage) /
              _usages.length;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryCard(totalUsed, averageUsage, _usages.length),
                  const SizedBox(height: 20),
                  const Text(
                    'Historia spalania',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ..._usages.map((usage) => InkWell(
                    onTap: () => _showUsageDetails(context, usage),
                    child: _buildUsageCard(usage),
                  )).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showUsageDetails(BuildContext context, CoalUsage usage) async {
    final updatedUsage = await showModalBottomSheet<CoalUsage>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UsageDetailsDialog(usage: usage),
    );

    if (updatedUsage != null) {
      setState(() {
        final index = _usages.indexWhere((u) => u.id == updatedUsage.id);
        if (index != -1) {
          _usages[index] = updatedUsage;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uwagi zaktualizowane')),
      );
    }
  }

  Widget _buildSummaryCard(double totalUsed, double averageUsage, int count) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Podsumowanie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Łącznie zużyto:'),
                Text('${totalUsed.toStringAsFixed(2)} kg'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Średnie zużycie dzienne:'),
                Text('${averageUsage.toStringAsFixed(2)} kg/dzień'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Liczba zapisów:'),
                Text('$count'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard(CoalUsage usage) {
    final startDate = usage.startDate;
    final endDate = usage.endDate;
    final heatPurposes = usage.heatPurposes;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heatPurposes != null && heatPurposes.isNotEmpty) ...[
              Text('Przeznaczenie: ${heatPurposes.join(', ')}'),
              const SizedBox(height: 8),
            ],
            Text(
              '${usage.amount?.toStringAsFixed(2) ?? '0.00'} kg przez ${usage.daysLasted ?? 0} dni',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${usage.dailyUsage.toStringAsFixed(2)} kg/dzień'),
                        Text('${usage.averageTemperature?.toStringAsFixed(1) ?? '0.0'}°C'),
                        Text(usage.weatherConditions ?? ''),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (startDate != null && endDate != null) ...[
              const SizedBox(height: 8),
              Text(
                '${startDate.day}.${startDate.month}.${startDate.year} - '
                    '${endDate.day}.${endDate.month}.${endDate.year}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UsageDetailsDialog extends StatefulWidget {
  final CoalUsage usage;

  const _UsageDetailsDialog({required this.usage});

  @override
  State<_UsageDetailsDialog> createState() => _UsageDetailsDialogState();
}

class _UsageDetailsDialogState extends State<_UsageDetailsDialog> {
  late TextEditingController _notesController;
  CoalPurchase? _relatedPurchase;
  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.usage.notes);
    _loadRelatedPurchase();
  }

  Future<void> _loadRelatedPurchase() async {
    if (widget.usage.purchaseId != null) {
      try {
        final purchase = await DatabaseHelper.instance.getPurchaseById(widget.usage.purchaseId!);
        setState(() {
          _relatedPurchase = purchase;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotes() async {
    final updatedUsage = CoalUsage(
      id: widget.usage.id,
      amount: widget.usage.amount,
      daysLasted: widget.usage.daysLasted,
      averageTemperature: widget.usage.averageTemperature,
      weatherConditions: widget.usage.weatherConditions,
      startDate: widget.usage.startDate,
      endDate: widget.usage.endDate,
      notes: _notesController.text,
      purchaseId: widget.usage.purchaseId,
      supplierName: widget.usage.supplierName,
      heatPurposes: widget.usage.heatPurposes,
    );

    await DatabaseHelper.instance.updateUsage(updatedUsage);
    Navigator.pop(context, updatedUsage);
  }

  @override
  Widget build(BuildContext context) {
    final startDate = widget.usage.startDate;
    final endDate = widget.usage.endDate;
    final dateFormat = DateFormat('dd.MM.yyyy');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
            child: Text(
              'Szczegóły raportu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),

          if (_relatedPurchase != null) ...[
            const Text(
              'Powiązane zamówienie:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Dostawca: ${_relatedPurchase!.supplier}'),
            Text('Ilość: ${_relatedPurchase!.amount.toStringAsFixed(2)} kg'),
            Text('Data: ${dateFormat.format(_relatedPurchase!.date)}'),
            const SizedBox(height: 16),
          ] else if (widget.usage.supplierName != null) ...[
            const Text(
              'Dostawca:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.usage.supplierName!),
            const SizedBox(height: 16),
          ],

          if (widget.usage.heatPurposes != null && widget.usage.heatPurposes!.isNotEmpty) ...[
            const Text(
              'Przeznaczenie ciepła:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.usage.heatPurposes!.join(', ')),
            const SizedBox(height: 16),
          ],

          const Text(
            'Ilość węgla:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('${widget.usage.amount?.toStringAsFixed(2) ?? '0.00'} kg'),
          const SizedBox(height: 8),

          const Text(
            'Czas trwania:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('${widget.usage.daysLasted ?? 0} dni'),
          const SizedBox(height: 8),

          const Text(
            'Dzienne zużycie:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('${widget.usage.dailyUsage.toStringAsFixed(2)} kg/dzień'),
          const SizedBox(height: 8),

          if (startDate != null && endDate != null) ...[
            const Text(
              'Okres:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}'),
            const SizedBox(height: 8),
          ],

          if (widget.usage.averageTemperature != null) ...[
            const Text(
              'Średnia temperatura:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${widget.usage.averageTemperature?.toStringAsFixed(1)}°C'),
            const SizedBox(height: 8),
          ],

          if (widget.usage.weatherConditions != null && widget.usage.weatherConditions!.isNotEmpty) ...[
            const Text(
              'Warunki pogodowe:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.usage.weatherConditions!),
            const SizedBox(height: 8),
          ],

          const Text(
            'Uwagi:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_isEditing) ...[
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Wpisz uwagi...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _notesController.text = widget.usage.notes ?? '';
                    });
                  },
                  child: const Text('Anuluj'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveNotes,
                  child: const Text('Zapisz'),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: Text(
                widget.usage.notes?.isNotEmpty == true
                    ? widget.usage.notes!
                    : 'Brak uwag (kliknij, aby dodać)',
                style: TextStyle(
                  fontStyle: widget.usage.notes?.isNotEmpty == true
                      ? FontStyle.italic
                      : FontStyle.normal,
                  color: widget.usage.notes?.isNotEmpty == true
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zamknij'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}