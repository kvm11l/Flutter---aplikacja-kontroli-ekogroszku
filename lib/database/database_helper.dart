// database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/coal_purchase.dart';
import '../models/coal_usage.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('eco_coal.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
        CREATE TABLE purchases (
          id TEXT PRIMARY KEY,
          supplier TEXT NOT NULL,
          amount REAL NOT NULL,
          price REAL NOT NULL,
          date INTEGER NOT NULL,
          notes TEXT
        )
    ''');

    await db.execute('''
        CREATE TABLE usages (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            days_lasted INTEGER NOT NULL,
            average_temperature REAL NOT NULL,
            weather_conditions TEXT NOT NULL,
            start_date INTEGER NOT NULL,
            end_date INTEGER NOT NULL,
            notes TEXT,
            purchase_id TEXT,
            heat_purposes TEXT, 
            FOREIGN KEY (purchase_id) REFERENCES purchases (id)
        )
    ''');

    await db.execute('''
    CREATE TABLE inventory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_id TEXT NOT NULL,
      remaining_amount REAL NOT NULL,
      FOREIGN KEY (purchase_id) REFERENCES purchases (id)
    )
    ''');

    await db.execute('''
  CREATE TABLE purchase_notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    purchase_id TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (purchase_id) REFERENCES purchases (id)
  )
''');
  }

  // Operacje na zakupach
  Future<int> createPurchase(CoalPurchase purchase) async {
    final db = await instance.database;
    return await db.insert('purchases', purchase.toMap());
  }

  Future<List<CoalPurchase>> getAllPurchases() async {
    final db = await instance.database;
    final result = await db.query('purchases', orderBy: 'date DESC');
    return result.map((json) => CoalPurchase.fromMap(json)).toList();
  }

  // Operacje na spalaniu
  Future<int> createUsage(CoalUsage usage) async {
    final db = await instance.database;
    return await db.insert('usages', usage.toMap());
  }

  Future<List<CoalUsage>> getAllUsages() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('usages');
    return List.generate(maps.length, (i) {
      return CoalUsage.fromMap(maps[i]);
    });
  }


  Future<int> updateUsage(CoalUsage usage) async {
    final db = await instance.database;
    return await db.update(
      'usages',
      usage.toMap(),
      where: 'id = ?',
      whereArgs: [usage.id],
    );
  }

  // Operacje na magazynie
  Future<int> addToInventory(String purchaseId, double amount) async {
    final db = await instance.database;
    return await db.insert('inventory', {
      'purchase_id': purchaseId,
      'remaining_amount': amount,
    });
  }

  Future<List<Map<String, dynamic>>> getCurrentInventory() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT p.*, i.remaining_amount 
      FROM inventory i
      JOIN purchases p ON i.purchase_id = p.id
      WHERE i.remaining_amount > 0
      ORDER BY p.date
    ''');
  }

  Future<int> updateInventory(String purchaseId, double newAmount) async {
    final db = await instance.database;
    return await db.update(
      'inventory',
      {'remaining_amount': newAmount},
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
  }

  Future<double> getTotalInventory() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT SUM(remaining_amount) as total FROM inventory WHERE remaining_amount > 0'
    );
    return result.first['total'] as double? ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getPurchaseUsageHistory(String purchaseId) async {
    final db = await instance.database;
    return await db.rawQuery('''
    SELECT u.amount, u.days_lasted as days, u.average_temperature as temp,
           u.start_date, u.end_date
    FROM usages u
    WHERE u.purchase_id = ?
    ORDER BY u.start_date DESC
  ''', [purchaseId]);
  }

  Future<List<Map<String, dynamic>>> getPurchaseNotes(String purchaseId) async {
    final db = await instance.database;
    return await db.query(
      'purchase_notes',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> updateNote(int id, String newContent) async {
    final db = await instance.database;
    return await db.update(
      'purchase_notes',
      {'content': newContent},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // database_helper.dart
  Future<int> deleteUsage(int id) async {
    final db = await instance.database;
    return await db.delete(
      'usages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CoalUsage>> getUsagesInDateRange(DateTime start, DateTime end) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
    SELECT * FROM usages 
    WHERE start_date <= ? AND end_date >= ?
    ORDER BY start_date
  ''', [end.millisecondsSinceEpoch, start.millisecondsSinceEpoch]);

    return result.map((json) => CoalUsage.fromMap(json)).toList();
  }

  // database_helper.dart
  Future<CoalPurchase?> getPurchaseById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'purchases',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CoalPurchase.fromMap(maps.first);
    }
    return null;
  }


  Future close() async {
    final db = await instance.database;
    db.close();
  }
}