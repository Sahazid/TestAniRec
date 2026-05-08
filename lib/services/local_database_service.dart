import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/app_user.dart';

class LocalDatabaseService {
  static const _dbName = 'anirec.db';
  static const _sessionUserKey = 'active_user_id';
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, _dbName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'user',
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE user_watchlist(
            user_id INTEGER NOT NULL,
            anime_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            PRIMARY KEY(user_id, anime_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE search_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            query TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE app_meta(
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode('anirec_salt::$password');
    return sha256.convert(bytes).toString();
  }

  Future<AppUser> registerUser({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final normalizedEmail = email.trim().toLowerCase();
    final role = normalizedEmail == 'admin@anirec.com' ? 'admin' : 'user';
    final id = await db.insert('users', {
      'email': normalizedEmail,
      'password_hash': _hashPassword(password),
      'role': role,
      'created_at': now,
    });
    final user = AppUser(
      id: id,
      email: normalizedEmail,
      role: role,
      createdAt: DateTime.parse(now),
    );
    await setActiveUserId(user.id);
    return user;
  }

  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final normalizedEmail = email.trim().toLowerCase();
    final rows = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [normalizedEmail, _hashPassword(password)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final user = _rowToUser(rows.first);
    await setActiveUserId(user.id);
    return user;
  }

  Future<void> logout() async {
    await setActiveUserId(null);
  }

  Future<void> setActiveUserId(int? userId) async {
    final db = await database;
    if (userId == null) {
      await db.delete('app_meta', where: 'key = ?', whereArgs: [_sessionUserKey]);
      return;
    }
    await db.insert(
      'app_meta',
      {'key': _sessionUserKey, 'value': userId.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AppUser?> getActiveUser() async {
    final db = await database;
    final meta = await db.query('app_meta', where: 'key = ?', whereArgs: [_sessionUserKey], limit: 1);
    if (meta.isEmpty) return null;
    final userId = int.tryParse(meta.first['value']?.toString() ?? '');
    if (userId == null) return null;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    if (rows.isEmpty) return null;
    return _rowToUser(rows.first);
  }

  Future<List<int>> getUserWatchlistIds(int userId) async {
    final db = await database;
    final rows = await db.query('user_watchlist', where: 'user_id = ?', whereArgs: [userId]);
    return rows.map((row) => row['anime_id'] as int).toList();
  }

  Future<void> toggleWatchlist({
    required int userId,
    required int animeId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'user_watchlist',
      where: 'user_id = ? AND anime_id = ?',
      whereArgs: [userId, animeId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await db.delete('user_watchlist', where: 'user_id = ? AND anime_id = ?', whereArgs: [userId, animeId]);
    } else {
      await db.insert('user_watchlist', {
        'user_id': userId,
        'anime_id': animeId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> logSearch({int? userId, required String query}) async {
    final db = await database;
    await db.insert('search_logs', {
      'user_id': userId,
      'query': query.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, int>> adminStats() async {
    final db = await database;
    final users = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
    final searches = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM search_logs')) ?? 0;
    final watchlistItems = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM user_watchlist')) ?? 0;
    return {'users': users, 'searches': searches, 'watchlistItems': watchlistItems};
  }

  Future<List<AppUser>> latestUsers({int limit = 10}) async {
    final db = await database;
    final rows = await db.query('users', orderBy: 'id DESC', limit: limit);
    return rows.map(_rowToUser).toList();
  }

  Future<void> updatePasswordByEmail({
    required String email,
    required String newPassword,
  }) async {
    final db = await database;
    final normalizedEmail = email.trim().toLowerCase();
    await db.update(
      'users',
      {'password_hash': _hashPassword(newPassword)},
      where: 'email = ?',
      whereArgs: [normalizedEmail],
    );
  }

  AppUser _rowToUser(Map<String, Object?> row) {
    return AppUser(
      id: row['id'] as int,
      email: row['email'] as String,
      role: row['role'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
