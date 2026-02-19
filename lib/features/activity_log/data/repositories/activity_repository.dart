import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/activity_entry.dart';

/// SQLite repository for [ActivityEntry] persistence.
class ActivityRepository {
  static const String _tableName = 'activity_log';

  // Shared database instance injected from the app-level initialisation.
  final Database Function() _dbProvider;

  const ActivityRepository({required Database Function() dbProvider})
      : _dbProvider = dbProvider;

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id         TEXT PRIMARY KEY,
        contactId  TEXT NOT NULL,
        type       TEXT NOT NULL DEFAULT 'note',
        title      TEXT NOT NULL,
        body       TEXT NOT NULL DEFAULT '',
        createdAt  TEXT NOT NULL
      )
    ''');
  }

  Future<void> insert(ActivityEntry entry) async {
    await _dbProvider().insert(
      _tableName,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ActivityEntry>> getByContact(String contactId) async {
    final maps = await _dbProvider().query(
      _tableName,
      where: 'contactId = ?',
      whereArgs: [contactId],
      orderBy: 'createdAt DESC',
    );
    return maps.map(ActivityEntry.fromMap).toList();
  }

  Future<void> delete(String id) async {
    await _dbProvider()
        .delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByContact(String contactId) async {
    await _dbProvider().delete(
      _tableName,
      where: 'contactId = ?',
      whereArgs: [contactId],
    );
  }
}

/// Standalone helper to open (or reuse) the shared app database.
Future<Database> openAppDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'real_estate_crm.db');
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Contacts table creation is handled by ContactRepository._onCreate.
      await ActivityRepository.createTable(db);
    },
    onOpen: (db) async {
      await ActivityRepository.createTable(db);
    },
  );
}
