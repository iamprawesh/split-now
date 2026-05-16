import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'splitwise_cache.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_groups (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_expenses (
            id TEXT PRIMARY KEY,
            group_id TEXT NOT NULL,
            data TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_actions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action_type TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            body TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // Cache groups
  Future<void> cacheGroups(List<Map<String, dynamic>> groups) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final group in groups) {
      batch.insert(
        'cached_groups',
        {
          'id': group['_id'] ?? group['id'],
          'data': group.toString(),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>?> getCachedGroups() async {
    final db = await database;
    final results = await db.query('cached_groups', orderBy: 'updated_at DESC');
    if (results.isEmpty) return null;
    return results.map((r) => r['data'] as Map<String, dynamic>).toList();
  }

  // Pending actions for offline queue
  Future<void> addPendingAction(
      String type, String endpoint, Map<String, dynamic>? body) async {
    final db = await database;
    await db.insert('pending_actions', {
      'action_type': type,
      'endpoint': endpoint,
      'body': body?.toString(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await database;
    return db.query('pending_actions', orderBy: 'created_at ASC');
  }

  Future<void> removePendingAction(int id) async {
    final db = await database;
    await db.delete('pending_actions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('cached_groups');
    await db.delete('cached_expenses');
    await db.delete('pending_actions');
  }
}
