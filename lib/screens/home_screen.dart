import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:projekt_njp/screens/usage_screen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../database/database_helper.dart';
import '../models/coal_usage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _currentInventory = 0.0;
  double? _temperature;
  String? _weatherDescription;
  int? _weatherIconCode;
  List<Map<String, dynamic>> _forecast = [];
  DateTime _selectedMonth = DateTime.now();
  Future<Map<String, dynamic>> _monthlyStats = Future.value({
    'averageDailyUsage': 0.0,
    'heatDistribution': <String, double>{},
    'chartData': <DailyUsage>[],
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _fetchWeather();
    });
  }

  Future<void> _loadData() async {
    final inventory = await DatabaseHelper.instance.getTotalInventory();
    setState(() {
      _currentInventory = inventory;
      _monthlyStats = _getMonthlyStats(_selectedMonth);
    });
  }

  Future<Map<String, dynamic>> _getMonthlyStats(DateTime month) async {
    try {
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final usages = await DatabaseHelper.instance.getUsagesInDateRange(firstDay, lastDay);

      if (usages.isEmpty) {
        return {
          'averageDailyUsage': 0.0,
          'heatDistribution': <String, double>{},
          'chartData': <DailyUsage>[],
        };
      }

      final totalUsed = usages.fold<double>(
          0,
              (sum, usage) => sum + (usage.amount ?? 0)
      );
      final daysInMonth = lastDay.day;
      final averageDailyUsage = totalUsed / daysInMonth;

      final heatDistribution = <String, double>{};
      for (final usage in usages) {
        for (final purpose in usage.heatPurposes ?? []) {
          heatDistribution[purpose] = (heatDistribution[purpose] ?? 0) + (usage.amount ?? 0);
        }
      }

      final chartData = <DailyUsage>[];
      for (var day = 1; day <= daysInMonth; day++) {
        final date = DateTime(month.year, month.month, day);
        final dailyUsages = usages.where((u) =>
        (u.startDate?.isBefore(date.add(const Duration(days: 1))) ?? false) &&
            (u.endDate?.isAfter(date) ?? false));

        final dailyAmount = dailyUsages.fold<double>(
            0,
                (sum, usage) => sum + (usage.dailyUsage)
        );

        chartData.add(DailyUsage(date, dailyAmount));
      }

      return {
        'averageDailyUsage': averageDailyUsage,
        'heatDistribution': heatDistribution,
        'chartData': chartData,
      };
    } catch (e) {
      print('Błąd ładowania statystyk: $e');
      return {
        'averageDailyUsage': 0.0,
        'heatDistribution': <String, double>{},
        'chartData': <DailyUsage>[],
      };
    }
  }

  Future<void> _loadInventory() async {
    final inventory = await DatabaseHelper.instance.getCurrentInventory();
    double total = 0;
    for (var item in inventory) {
      total += item['remaining_amount'] ?? 0;
    }
    setState(() {
      _currentInventory = total;
    });
  }

  void _navigateToUsageScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UsageScreen()),
    );

    // Jeśli wynik jest true, odśwież dane
    if (result == true) {
      await _loadInventory();
    }
  }

  Future<void> _fetchWeather() async {
    const latitude = 50.8118; // Częstochowa
    const longitude = 19.1203;

    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        final daily = data['daily'];

        setState(() {
          _temperature = current['temperature_2m']?.toDouble();
          _weatherIconCode = current['weather_code']?.toInt();
          _weatherDescription = _mapWeatherCodeToDescription(_weatherIconCode ?? 0);

          _forecast = List.generate(3, (index) {
            return {
              'date': daily['time'][index + 1],
              'max': daily['temperature_2m_max'][index + 1]?.toDouble(),
              'min': daily['temperature_2m_min'][index + 1]?.toDouble(),
              'code': daily['weather_code'][index + 1]?.toInt(),
            };
          });
        });
      }
    } catch (e) {
      print('Błąd pobierania pogody: $e');
    }
  }

  String _mapWeatherCodeToDescription(int code) {
    if (code == 0) return 'Słonecznie';
    if (code == 1 || code == 2) return 'Częściowo pochmurno';
    if (code == 3) return 'Pochmurno';
    if (code >= 45 && code <= 48) return 'Mgła';
    if (code >= 51 && code <= 57) return 'Mżawka';
    if (code >= 61 && code <= 67) return 'Deszcz';
    if (code >= 71 && code <= 77) return 'Śnieg';
    if (code >= 80 && code <= 82) return 'Przelotne opady';
    if (code >= 95) return 'Burza';
    return 'Nieznana pogoda';
  }

  Icon _getWeatherIcon(int code) {
    if (code == 0) return const Icon(Icons.wb_sunny, color: Colors.orange, size: 48);
    if (code == 1 || code == 2) return const Icon(Icons.wb_cloudy, size: 48);
    if (code == 3) return const Icon(Icons.cloud, size: 48);
    if (code >= 45 && code <= 48) return const Icon(Icons.blur_on, size: 48);
    if (code >= 51 && code <= 57) return const Icon(Icons.grain, size: 48);
    if (code >= 61 && code <= 67) return const Icon(Icons.umbrella, size: 48);
    if (code >= 71 && code <= 77) return const Icon(Icons.ac_unit, size: 48);
    if (code >= 80 && code <= 82) return const Icon(Icons.grain, size: 48);
    if (code >= 95) return const Icon(Icons.flash_on, size: 48);
    return const Icon(Icons.help_outline, size: 48);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _monthlyStats = _getMonthlyStats(_selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontrola Ekogroszku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadData();
              _fetchWeather();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWeatherInfo(),
            _buildForecast(),
            _buildInventoryCard(),
            _buildMonthlyStatsSection(),
            const SizedBox(height: 20),
            _buildQuickActions(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildWeatherInfo() {
    if (_temperature == null || _weatherIconCode == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Częstochowa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getWeatherIcon(_weatherIconCode!),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_temperature?.toStringAsFixed(1)}°C',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _weatherDescription ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecast() {
    if (_forecast.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prognoza (3 dni):',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Column(
            children: _forecast.map((day) {
              return Card(
                child: ListTile(
                  leading: Tooltip(
                    message: _mapWeatherCodeToDescription(day['code'] as int),
                    child: _getWeatherIcon(day['code'] as int),
                  ),
                  title: Text(day['date'].toString()),
                  subtitle: Text(
                    'Min: ${(day['min'] as double?)?.toStringAsFixed(1) ?? '0.0'}°C, '
                        'Max: ${(day['max'] as double?)?.toStringAsFixed(1) ?? '0.0'}°C',
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _monthlyStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {
          'averageDailyUsage': 0.0,
          'heatDistribution': <String, double>{},
          'chartData': <DailyUsage>[],
        };

        return Column(
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 16),
            _buildAverageUsageCard(data['averageDailyUsage'] as double),
            const SizedBox(height: 16),
            _buildHeatDistributionChart(data['heatDistribution'] as Map<String, double>),
            const SizedBox(height: 16),
            _buildDailyUsageChart(data['chartData'] as List<DailyUsage>),
          ],
        );
      },
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_selectedMonth),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildAverageUsageCard(double averageUsage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Średnie dzienne zużycie',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${averageUsage.toStringAsFixed(2)} kg/dzień',
              style: const TextStyle(fontSize: 24, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatDistributionChart(Map<String, double> distribution) {
    final data = distribution.entries
        .map((e) => ChartData(e.key, e.value))
        .toList();

    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Brak danych o rozkładzie ciepła'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Rozkład przeznaczenia ciepła',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelMapper: (ChartData data, _) => '${data.x}: ${data.y.toStringAsFixed(1)}kg',
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyUsageChart(List<DailyUsage> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Brak danych o dziennym zużyciu'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Dzienne zużycie',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <ChartSeries>[
                  ColumnSeries<DailyUsage, String>(
                    dataSource: data,
                    xValueMapper: (DailyUsage usage, _) =>
                        DateFormat('dd').format(usage.date),
                    yValueMapper: (DailyUsage usage, _) => usage.amount,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard() {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Aktualne zapasy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${_currentInventory.toStringAsFixed(2)} kg',
              style: const TextStyle(fontSize: 32, color: Colors.orange),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _currentInventory / 1000,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _navigateToUsageScreen,
              child: const Text('Zarejestruj spalanie'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () async {
            final shouldRefresh = await Navigator.pushNamed(context, '/purchase');
            if (shouldRefresh == true) _loadData();
          },
          child: const Column(
            children: [
              Icon(Icons.add_shopping_cart),
              Text('Nowy zakup'),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final shouldRefresh = await Navigator.pushNamed(context, '/usage');
            if (shouldRefresh == true) _loadData();
          },
          child: const Column(
            children: [
              Icon(Icons.local_fire_department),
              Text('Rejestruj spalanie'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Strona główna',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Historia',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Raporty',
        ),
      ],
      onTap: (index) {
        if (index == 1) Navigator.pushNamed(context, '/history');
        if (index == 2) Navigator.pushNamed(context, '/reports');
      },
    );
  }
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}

class DailyUsage {
  final DateTime date;
  final double amount;

  DailyUsage(this.date, this.amount);
}