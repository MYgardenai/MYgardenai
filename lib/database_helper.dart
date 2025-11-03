import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'mygardenai.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE plants(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE photos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        type TEXT NOT NULL,  -- e.g., 'scan', 'pest'
        captured_at INTEGER NOT NULL,
        FOREIGN KEY (plant_id) REFERENCES plants (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE plants ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE plants ADD COLUMN longitude REAL');
    }
  }

  Future<int> insertPlant(String name, {double? latitude, double? longitude}) async {
    final db = await database;
    return await db.insert('plants', {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>?> getPlantWithLocation(String name) async {
    final db = await database;
    final result = await db.query('plants', where: 'name = ?', whereArgs: [name]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getPlantsWithLocations() async {
    final db = await database;
    return await db.query('plants', orderBy: 'created_at DESC');
  }

  Future<void> updatePlantLocation(int id, double latitude, double longitude) async {
    final db = await database;
    await db.update('plants', {'latitude': latitude, 'longitude': longitude}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertPhoto(int plantId, String filePath, String type) async {
    final db = await database;
    await db.insert('photos', {
      'plant_id': plantId,
      'file_path': filePath,
      'type': type,
      'captured_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getPhotosForPlant(int plantId) async {
    final db = await database;
    return await db.query('photos',
        where: 'plant_id = ?', whereArgs: [plantId],
        orderBy: 'captured_at DESC');
  }

  Future<List<Map<String, dynamic>>> getPlants() async {
    final db = await database;
    return await db.query('plants', orderBy: 'created_at DESC');
  }
}
