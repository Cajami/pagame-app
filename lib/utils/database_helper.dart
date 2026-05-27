import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:pagame/models/category_item.dart';
import 'package:pagame/models/service_item.dart';
import 'package:pagame/models/payment_record.dart';

class DatabaseHelper {
  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'pagame.db');

    return await openDatabase(
      path,
      version: 6, // Incremented version to 6 to clean up type and notify_1_day columns
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys support
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categorias (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_codepoint INTEGER NOT NULL,
        color_value INTEGER NOT NULL
      )
    ''');

    // Create newer version 2 tables
    await _createV2Tables(db);
    
    // Create newer version 3 tables
    await _createV3Tables(db);

    // Create newer version 4 tables
    await _createV4Tables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
    }
    if (oldVersion < 3) {
      await _createV3Tables(db);
    }
    if (oldVersion < 4) {
      await _upgradeToV4(db);
    }
    if (oldVersion < 5) {
      await _upgradeToV5(db);
    }
    if (oldVersion >= 2 && oldVersion < 6) {
      await _upgradeToV6(db);
    }
  }

  Future<void> _createV2Tables(Database db) async {
    // Create services table
    await db.execute('''
      CREATE TABLE servicios (
        id TEXT PRIMARY KEY,
        categoria_id TEXT NOT NULL,
        name TEXT NOT NULL,
        billing_cycle TEXT NOT NULL,
        reminders_enabled INTEGER DEFAULT 0,
        reminder_hour INTEGER DEFAULT 8,
        reminder_minute INTEGER DEFAULT 0,
        notify_5_days INTEGER DEFAULT 1,
        notify_same_day INTEGER DEFAULT 1,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE CASCADE
      )
    ''');

    // Create years table
    await db.execute('''
      CREATE TABLE anios (
        id TEXT PRIMARY KEY,
        servicio_id TEXT NOT NULL,
        anio INTEGER NOT NULL,
        FOREIGN KEY (servicio_id) REFERENCES servicios(id) ON DELETE CASCADE,
        UNIQUE(servicio_id, anio)
      )
    ''');

    // Create months table
    await db.execute('''
      CREATE TABLE meses (
        id TEXT PRIMARY KEY,
        anio_id TEXT NOT NULL,
        mes INTEGER NOT NULL,
        FOREIGN KEY (anio_id) REFERENCES anios(id) ON DELETE CASCADE,
        UNIQUE(anio_id, mes)
      )
    ''');
  }

  Future<void> _createV3Tables(Database db) async {
    // Create payments table
    await db.execute('''
      CREATE TABLE pagos (
        id TEXT PRIMARY KEY,
        mes_id TEXT NOT NULL,
        monto REAL,
        estado TEXT NOT NULL,
        fecha_pago TEXT NOT NULL,
        notas TEXT,
        adjuntos TEXT,
        moneda TEXT DEFAULT 'PEN',
        FOREIGN KEY (mes_id) REFERENCES meses(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createV4Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS config (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeToV4(Database db) async {
    // 1. Add new columns to 'servicios' table
    try {
      await db.execute('ALTER TABLE servicios ADD COLUMN reminders_enabled INTEGER DEFAULT 0');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE servicios ADD COLUMN reminder_hour INTEGER DEFAULT 8');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE servicios ADD COLUMN reminder_minute INTEGER DEFAULT 0');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE servicios ADD COLUMN notify_5_days INTEGER DEFAULT 1');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE servicios ADD COLUMN notify_1_day INTEGER DEFAULT 1');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE servicios ADD COLUMN notify_same_day INTEGER DEFAULT 1');
    } catch (_) {}

    // 2. Create the 'config' table
    await _createV4Tables(db);
  }

  Future<void> _upgradeToV5(Database db) async {
    try {
      await db.execute("ALTER TABLE pagos ADD COLUMN moneda TEXT DEFAULT 'PEN'");
    } catch (_) {}
  }

  Future<void> _upgradeToV6(Database db) async {
    // Drop columns (type and notify_1_day) using the standard SQLite recreation procedure
    try {
      // 1. Rename old table
      await db.execute('ALTER TABLE servicios RENAME TO servicios_old');

      // 2. Create the clean modern table
      await db.execute('''
        CREATE TABLE servicios (
          id TEXT PRIMARY KEY,
          categoria_id TEXT NOT NULL,
          name TEXT NOT NULL,
          billing_cycle TEXT NOT NULL,
          reminders_enabled INTEGER DEFAULT 0,
          reminder_hour INTEGER DEFAULT 8,
          reminder_minute INTEGER DEFAULT 0,
          notify_5_days INTEGER DEFAULT 1,
          notify_same_day INTEGER DEFAULT 1,
          FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE CASCADE
        )
      ''');

      // 3. Map and copy data from the old table to the new one
      await db.execute('''
        INSERT INTO servicios (
          id, categoria_id, name, billing_cycle, reminders_enabled,
          reminder_hour, reminder_minute, notify_5_days, notify_same_day
        )
        SELECT 
          id, categoria_id, name, billing_cycle, reminders_enabled,
          reminder_hour, reminder_minute, notify_5_days, notify_same_day
        FROM servicios_old
      ''');

      // 4. Drop the old backup table
      await db.execute('DROP TABLE servicios_old');
      
      debugPrint('SQLite: Upgraded to V6 (removed type and notify_1_day columns).');
    } catch (e) {
      debugPrint('Error during SQLite V6 migration: $e');
    }
  }

  // --- CONFIG / SETTINGS CRUD ---

  Future<void> saveConfig(String key, String value) async {
    final db = await database;
    await db.insert(
      'config',
      {
        'clave': key,
        'valor': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getConfig(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'config',
      where: 'clave = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['valor'] as String;
  }

  // --- CATEGORIES CRUD ---

  Future<int> insertCategory(CategoryItem category) async {
    final db = await database;
    return await db.insert(
      'categorias',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CategoryItem>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categorias',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return List.generate(maps.length, (i) {
      return CategoryItem.fromMap(maps[i]);
    });
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCategory(CategoryItem category) async {
    final db = await database;
    return await db.update(
      'categorias',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // --- SERVICES CRUD ---

  Future<int> insertService(ServiceItem service) async {
    final db = await database;
    return await db.insert(
      'servicios',
      service.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ServiceItem>> getServicesForCategory(String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'servicios',
      where: 'categoria_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    final List<ServiceItem> services = [];
    for (final map in maps) {
      final service = ServiceItem.fromMap(map);
      await _loadTimelineForService(db, service);
      services.add(service);
    }
    return services;
  }

  Future<void> _loadTimelineForService(Database db, ServiceItem service) async {
    final List<Map<String, dynamic>> yearMaps = await db.query(
      'anios',
      where: 'servicio_id = ?',
      whereArgs: [service.id],
    );

    for (final yMap in yearMaps) {
      final yearId = yMap['id'] as String;
      final year = yMap['anio'] as int;

      service.monthsByYear[year] = <int>{};

      final List<Map<String, dynamic>> monthMaps = await db.query(
        'meses',
        where: 'anio_id = ?',
        whereArgs: [yearId],
      );

      for (final mMap in monthMaps) {
        final month = mMap['mes'] as int;
        service.monthsByYear[year]!.add(month);
        
        // Load in-memory payments from SQLite if needed to keep in-memory maps in sync
        final periodKey = '$year-$month';
        final payments = await getPaymentsForMonth(db: db, monthId: '${yearId}_$month');
        service.paymentsByPeriod[periodKey] = payments;
      }
    }
  }

  // --- YEARS AND MONTHS CRUD ---

  Future<int> insertYear(String id, String serviceId, int year) async {
    final db = await database;
    return await db.insert(
      'anios',
      {
        'id': id,
        'servicio_id': serviceId,
        'anio': year,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> insertMonth(String id, String yearId, int month) async {
    final db = await database;
    return await db.insert(
      'meses',
      {
        'id': id,
        'anio_id': yearId,
        'mes': month,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // --- PAYMENTS CRUD ---

  /// Inserts a payment record linked to a month.
  Future<int> insertPayment(String monthId, PaymentRecord payment) async {
    final db = await database;
    return await db.insert(
      'pagos',
      {
        'id': payment.id,
        'mes_id': monthId,
        'monto': payment.amount,
        'estado': payment.status,
        'fecha_pago': payment.paymentDate.toIso8601String(),
        'notas': payment.notes,
        'adjuntos': jsonEncode(payment.attachments),
        'moneda': payment.moneda,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all payments for a specific month, ordered by date descending.
  Future<List<PaymentRecord>> getPaymentsForMonth({Database? db, required String monthId}) async {
    final activeDb = db ?? await database;
    final List<Map<String, dynamic>> maps = await activeDb.query(
      'pagos',
      where: 'mes_id = ?',
      whereArgs: [monthId],
      orderBy: 'fecha_pago DESC',
    );

    return List.generate(maps.length, (i) {
      final adjuntosRaw = maps[i]['adjuntos'] as String?;
      final List<String> adjuntos = adjuntosRaw != null
          ? List<String>.from(jsonDecode(adjuntosRaw) as List)
          : const [];
      final dateStr = maps[i]['fecha_pago'] as String;

      return PaymentRecord(
        id: maps[i]['id'] as String,
        status: maps[i]['estado'] as String,
        amount: maps[i]['monto'] as double?,
        paymentDate: DateTime.parse(dateStr),
        notes: maps[i]['notas'] as String?,
        attachments: adjuntos,
        moneda: maps[i]['moneda'] as String? ?? 'PEN',
      );
    });
  }

  // --- DELETE AND UPDATE AUXILIARY METHODS ---

  Future<int> deleteService(String id) async {
    final db = await database;
    return await db.delete(
      'servicios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateService(ServiceItem service) async {
    final db = await database;
    return await db.update(
      'servicios',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteYear(String id) async {
    final db = await database;
    return await db.delete(
      'anios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMonth(String id) async {
    final db = await database;
    return await db.delete(
      'meses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePayment(String id) async {
    final db = await database;
    return await db.delete(
      'pagos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updatePayment(PaymentRecord payment) async {
    final db = await database;
    return await db.update(
      'pagos',
      {
        'monto': payment.amount,
        'estado': payment.status,
        'fecha_pago': payment.paymentDate.toIso8601String(),
        'notas': payment.notes,
        'adjuntos': jsonEncode(payment.attachments),
        'moneda': payment.moneda,
      },
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  // --- RAW DATABASE BACKUP METHODS ---

  Future<List<Map<String, dynamic>>> getAllCategoriesRaw() async {
    final db = await database;
    return await db.query('categorias');
  }

  Future<List<Map<String, dynamic>>> getAllServicesRaw() async {
    final db = await database;
    return await db.query('servicios');
  }

  Future<List<Map<String, dynamic>>> getAllYearsRaw() async {
    final db = await database;
    return await db.query('anios');
  }

  Future<List<Map<String, dynamic>>> getAllMonthsRaw() async {
    final db = await database;
    return await db.query('meses');
  }

  Future<List<Map<String, dynamic>>> getAllPaymentsRaw() async {
    final db = await database;
    return await db.query('pagos');
  }

  /// Returns a unique list of attachment file paths for a specific service,
  /// ordered chronologically (newest payments first).
  Future<List<String>> getUniqueAttachmentsForService(String serviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.adjuntos, p.fecha_pago
      FROM pagos p
      INNER JOIN meses m ON p.mes_id = m.id
      INNER JOIN anios a ON m.anio_id = a.id
      WHERE a.servicio_id = ?
      ORDER BY p.fecha_pago DESC
    ''', [serviceId]);

    final Set<String> uniquePaths = {};
    final List<String> orderedPaths = [];

    for (final map in maps) {
      final adjuntosRaw = map['adjuntos'] as String?;
      if (adjuntosRaw != null && adjuntosRaw.isNotEmpty) {
        try {
          final List<dynamic> paths = jsonDecode(adjuntosRaw) as List;
          for (final path in paths) {
            final pathStr = path as String;
            if (pathStr.isNotEmpty && uniquePaths.add(pathStr)) {
              orderedPaths.add(pathStr);
            }
          }
        } catch (_) {}
      }
    }
    return orderedPaths;
  }

  /// Returns a unique list of all attachment file paths in the entire app,
  /// ordered chronologically (newest payments first).
  Future<List<String>> getAllUniqueAttachments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT adjuntos, fecha_pago
      FROM pagos
      ORDER BY fecha_pago DESC
    ''');

    final Set<String> uniquePaths = {};
    final List<String> orderedPaths = [];

    for (final map in maps) {
      final adjuntosRaw = map['adjuntos'] as String?;
      if (adjuntosRaw != null && adjuntosRaw.isNotEmpty) {
        try {
          final List<dynamic> paths = jsonDecode(adjuntosRaw) as List;
          for (final path in paths) {
            final pathStr = path as String;
            if (pathStr.isNotEmpty && uniquePaths.add(pathStr)) {
              orderedPaths.add(pathStr);
            }
          }
        } catch (_) {}
      }
    }
    return orderedPaths;
  }

  // --- ANALYTICS / STATISTICS QUERIES ---

  /// Returns all services ordered alphabetically.
  Future<List<ServiceItem>> getAllServices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'servicios',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return List.generate(maps.length, (i) => ServiceItem.fromMap(maps[i]));
  }

  /// Returns category-wise expenses for a specific month and year, filtered by currency.
  Future<List<Map<String, dynamic>>> getMonthlyCategoryExpenses({
    required int year,
    required int month,
    required String moneda,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.id, c.name, c.color_value, SUM(p.monto) as total
      FROM pagos p
      INNER JOIN meses m ON p.mes_id = m.id
      INNER JOIN anios a ON m.anio_id = a.id
      INNER JOIN servicios s ON a.servicio_id = s.id
      INNER JOIN categorias c ON s.categoria_id = c.id
      WHERE a.anio = ? AND m.mes = ? AND p.moneda = ? AND p.monto IS NOT NULL
      GROUP BY c.id
    ''', [year, month, moneda]);
  }

  /// Returns historical payments for a specific service, filtered by currency.
  Future<List<Map<String, dynamic>>> getServicePaymentsHistory(String serviceId, String moneda) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT a.anio, m.mes, SUM(p.monto) as total
      FROM pagos p
      INNER JOIN meses m ON p.mes_id = m.id
      INNER JOIN anios a ON m.anio_id = a.id
      WHERE a.servicio_id = ? AND p.moneda = ? AND p.monto IS NOT NULL
      GROUP BY a.anio, m.mes
      ORDER BY a.anio ASC, m.mes ASC
    ''', [serviceId, moneda]);
  }
}
