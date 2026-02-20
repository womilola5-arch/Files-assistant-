import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tracked_file.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('file_memory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tracked_files (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        name TEXT NOT NULL,
        sizeBytes INTEGER NOT NULL,
        createdDate INTEGER NOT NULL,
        lastAccessedDate INTEGER,
        type INTEGER NOT NULL,
        thumbnailPath TEXT,
        isMarkedForDeletion INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_created_date ON tracked_files(createdDate)');
  }

  Future<TrackedFile> insert(TrackedFile file) async {
    final db = await instance.database;
    await db.insert('tracked_files', file.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return file;
  }

  Future<List<TrackedFile>> getAllFiles() async {
    final db = await instance.database;
    final result = await db.query('tracked_files', orderBy: 'createdDate DESC');
    return result.map((json) => TrackedFile.fromMap(json)).toList();
  }

  Future<List<TrackedFile>> getOldFiles({int monthsOld = 6}) async {
    final db = await instance.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: monthsOld * 30));
    final result = await db.query(
      'tracked_files',
      where: 'createdDate <= ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
      orderBy: 'createdDate ASC',
    );
    return result.map((json) => TrackedFile.fromMap(json)).toList();
  }

  Future<List<TrackedFile>> getLargeFiles({int minSizeMB = 50}) async {
    final db = await instance.database;
    final result = await db.query(
      'tracked_files',
      where: 'sizeBytes >= ?',
      whereArgs: [minSizeMB * 1024 * 1024],
      orderBy: 'sizeBytes DESC',
    );
    return result.map((json) => TrackedFile.fromMap(json)).toList();
  }

  Future<int> delete(String id) async {
    final db = await instance.database;
    return await db.delete('tracked_files', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMultiple(List<String> ids) async {
    final db = await instance.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete('tracked_files', where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Future<int> getTotalStorageUsed() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(sizeBytes) as total FROM tracked_files');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getFileCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM tracked_files');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('tracked_files');
  }
