import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class TradeExitDB {
  static final TradeExitDB instance = TradeExitDB._init();
  static Database? _database;

  TradeExitDB._init();

  Future<Database> get db async {
    if (_database != null) return _database!;
    _database = await _initDB("trade_exit.db");
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trade_exit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_name TEXT,
        share_name TEXT,
        product_type TEXT,
        exit_date TEXT,        
        customer_id TEXT,      
        executed_price TEXT,
        qty TEXT,
        avg_buy_price TEXT,
        exit_price TEXT,
        brokerage TEXT,
        buy_brokerage REAL DEFAULT 0,
        sell_brokerage REAL DEFAULT 0,
        realised_pl REAL
      );
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for buy_brokerage and sell_brokerage
      await db.execute('ALTER TABLE trade_exit ADD COLUMN buy_brokerage REAL DEFAULT 0');
      await db.execute('ALTER TABLE trade_exit ADD COLUMN sell_brokerage REAL DEFAULT 0');
    }
  }

  // INSERT ROW
  Future<int> insert(Map<String, dynamic> data) async {
    try {
      final database = await instance.db;

      // Validate required fields
      if (data["customer_id"] == null || data["customer_id"].toString().trim().isEmpty) {
        throw Exception("Customer ID is required");
      }
      if (data["share_name"] == null || data["share_name"].toString().trim().isEmpty) {
        throw Exception("Share name is required");
      }
      if (data["exit_date"] == null || data["exit_date"].toString().trim().isEmpty) {
        throw Exception("Exit date is required");
      }

      // Always save customer_id as TEXT
      data["customer_id"] = data["customer_id"].toString().trim();

      // Insert record
      final result = await database.insert("trade_exit", data);
      
      // Auto-cleanup: Remove previous week's data when Monday arrives (non-blocking)
      _cleanupWeeklyRecords().catchError((error) {
        // Log error but don't fail the insert
        print("Warning: Weekly cleanup failed: $error");
      });
      
      return result;
    } catch (e) {
      throw Exception("Failed to insert trade record: $e");
    }
  }

  // Weekly cleanup: Remove previous week's data (Monday to Sunday) when Monday arrives
  Future<void> _cleanupWeeklyRecords() async {
    try {
      final database = await instance.db;
      final now = DateTime.now();
      
      // Only cleanup on Monday
      if (now.weekday != DateTime.monday) {
        return;
      }

      // Calculate current week's Monday (start of current week)
      int daysFromMonday = (now.weekday - 1) % 7;
      DateTime currentMonday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: daysFromMonday));
      
      // Calculate previous week's Monday and Sunday
      DateTime previousMonday = currentMonday.subtract(const Duration(days: 7));
      DateTime previousSunday = previousMonday.add(const Duration(days: 6));
      
      // Format dates for comparison (dd/MM/yyyy)
      final dateFormat = DateFormat("dd/MM/yyyy");
      String previousMondayStr = dateFormat.format(previousMonday);
      String previousSundayStr = dateFormat.format(previousSunday);

      // Get all records and filter by date range
      List<Map<String, dynamic>> allRecords;
      try {
        allRecords = await database.query("trade_exit");
      } catch (e) {
        throw Exception("Failed to query records for cleanup: $e");
      }

      final List<int> idsToDelete = [];
      
      for (var record in allRecords) {
        final exitDateStr = record["exit_date"]?.toString() ?? "";
        if (exitDateStr.isEmpty) continue;
        
        try {
          final exitDateParsed = dateFormat.parse(exitDateStr);
          // Normalize to date only (remove time component)
          final exitDate = DateTime(exitDateParsed.year, exitDateParsed.month, exitDateParsed.day);
          final prevMon = DateTime(previousMonday.year, previousMonday.month, previousMonday.day);
          final prevSun = DateTime(previousSunday.year, previousSunday.month, previousSunday.day);
          
          // Check if date falls within previous week (Monday to Sunday inclusive)
          if (exitDate.isAfter(prevMon.subtract(const Duration(days: 1))) &&
              exitDate.isBefore(prevSun.add(const Duration(days: 1)))) {
            final id = record["id"];
            if (id != null && id is int) {
              idsToDelete.add(id);
            }
          }
        } catch (e) {
          // Skip records with invalid date format
          print("Warning: Invalid date format for record ${record["id"]}: $exitDateStr");
        }
      }
      
      // Delete all records in batch
      if (idsToDelete.isNotEmpty) {
        try {
          final placeholders = idsToDelete.map((_) => '?').join(',');
          final deletedCount = await database.delete(
            "trade_exit",
            where: "id IN ($placeholders)",
            whereArgs: idsToDelete,
          );
          print("Cleaned up $deletedCount records from previous week ($previousMondayStr to $previousSundayStr)");
        } catch (e) {
          throw Exception("Failed to delete old records: $e");
        }
      }
    } catch (e) {
      // Log error but don't fail the insert
      print("Warning: Failed to cleanup weekly records: $e");
      // Re-throw only if it's a critical error
      if (e.toString().contains("Failed to")) {
        rethrow;
      }
    }
  }

  // FETCH ALL TRADES
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final database = await instance.db;
    return await database.query("trade_exit", orderBy: "id DESC");
  }

  // -------------------------
  // FIXED: LAST 7 DAYS TRADES
  // -------------------------
  Future<List<Map<String, dynamic>>> getLast7DaysTrades(
    String customerId,
  ) async {
    final database = await instance.db;

    final sevenDaysAgo = DateFormat(
      "dd/MM/yyyy",
    ).format(DateTime.now().subtract(const Duration(days: 7)));

    return await database.query(
      "trade_exit",
      where: "customer_id = ? AND exit_date >= ?",
      whereArgs: [customerId.trim(), sevenDaysAgo],
      orderBy: "exit_date DESC",
    );
  }

  // -------------------------
  // FIXED: ALL TRADES OF CUSTOMER
  // -------------------------
  Future<List<Map<String, dynamic>>> getAllTradesByCustomer(
    String customerId,
  ) async {
    final database = await instance.db;

    return await database.query(
      'trade_exit',
      where: "customer_id = ?",
      whereArgs: [customerId.trim()],
      orderBy: "exit_date DESC",
    );
  }
}
