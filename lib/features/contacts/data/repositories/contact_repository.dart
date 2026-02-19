import 'dart:developer' as developer;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/contact_model.dart';

/// Low-level SQLite repository for [ContactModel] persistence.
///
/// The database lives locally on-device (local-first architecture).
class ContactRepository {
  static const String _dbName = 'real_estate_crm.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'contacts';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    developer.log('Opening database at $path', name: 'ContactRepository');
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id          TEXT    PRIMARY KEY,
        fullName    TEXT    NOT NULL,
        phone       TEXT    NOT NULL DEFAULT '',
        email       TEXT    NOT NULL DEFAULT '',
        dncStatus   INTEGER NOT NULL DEFAULT 0,
        leadSource  TEXT    NOT NULL DEFAULT '',
        address     TEXT    NOT NULL DEFAULT '{}',
        folderTag   TEXT    NOT NULL DEFAULT 'active',
        lastContactDate TEXT,
        createdAt   TEXT    NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations can be added here.
    developer.log(
      'DB upgrade from $oldVersion to $newVersion',
      name: 'ContactRepository',
    );
  }

  // --------------------------------------------------------------------------
  // CRUD
  // --------------------------------------------------------------------------

  Future<void> insert(ContactModel contact) async {
    final db = await database;
    await db.insert(
      _tableName,
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertAll(List<ContactModel> contacts) async {
    final db = await database;
    final batch = db.batch();
    for (final c in contacts) {
      batch.insert(_tableName, c.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(ContactModel contact) async {
    final db = await database;
    await db.update(
      _tableName,
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<ContactModel?> getById(String id) async {
    final db = await database;
    final maps =
        await db.query(_tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ContactModel.fromMap(maps.first);
  }

  Future<List<ContactModel>> getAll() async {
    final db = await database;
    final maps =
        await db.query(_tableName, orderBy: 'createdAt DESC');
    return maps.map(ContactModel.fromMap).toList();
  }

  Future<List<ContactModel>> getByFolder(FolderTag folder) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'folderTag = ?',
      whereArgs: [folder.name],
      orderBy: 'createdAt DESC',
    );
    return maps.map(ContactModel.fromMap).toList();
  }

  /// Full-text search across name, phone, city, and email.
  Future<List<ContactModel>> search(String query) async {
    if (query.trim().isEmpty) return getAll();
    final db = await database;
    final likeQuery = '%${query.trim()}%';
    final maps = await db.rawQuery(
      '''
      SELECT * FROM $_tableName
      WHERE fullName    LIKE ?
         OR phone       LIKE ?
         OR email       LIKE ?
         OR address     LIKE ?
      ORDER BY createdAt DESC
      ''',
      [likeQuery, likeQuery, likeQuery, likeQuery],
    );
    return maps.map(ContactModel.fromMap).toList();
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
