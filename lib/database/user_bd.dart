import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("customers.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT
      );
    ''');
  }

  // CHECK IF CUSTOMER ID EXISTS
  Future<bool> checkCustomerIdExists(dynamic id) async {
    final db = await instance.database;
    final result = await db.query(
      "customers",
      where: "id = ?",
      whereArgs: [id.toString()], // Always TEXT
    );
    return result.isNotEmpty;
  }

  // INSERT CUSTOMER
  Future<int> insertCustomer(Map<String, dynamic> data) async {
    final db = await instance.database;

    data["id"] = data["id"].toString(); // convert int → text

    return await db.insert("customers", data);
  }

  // GET CUSTOMER BY ID
  Future<Map<String, dynamic>?> getCustomerById(dynamic id) async {
    final db = await instance.database;
    final result = await db.query(
      "customers",
      where: "id = ?",
      whereArgs: [id.toString()], // Always TEXT
    );
    return result.isNotEmpty ? result.first : null;
  }

  // GET ALL CUSTOMERS
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await instance.database;
    return await db.query("customers", orderBy: "name ASC");
  }

  // UPDATE CUSTOMER
  Future<int> updateCustomer(String id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      "customers",
      data,
      where: "id = ?",
      whereArgs: [id.toString()],
    );
  }

  // DELETE CUSTOMER
  Future<int> deleteCustomer(String id) async {
    final db = await instance.database;
    return await db.delete(
      "customers",
      where: "id = ?",
      whereArgs: [id.toString()],
    );
  }
}
