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
            username TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'user',
            profile_image_path TEXT,
            is_blocked INTEGER NOT NULL DEFAULT 0,
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
        await db.execute('''
          CREATE TABLE custom_anime(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            image_url TEXT NOT NULL,
            synopsis TEXT NOT NULL,
            genres TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    await _migrateSchema(_db!);
    await _ensureAdminAccount();
    return _db!;
  }

  Future<void> _migrateSchema(Database db) async {
    await _safeAlter(db, 'ALTER TABLE users ADD COLUMN username TEXT NOT NULL DEFAULT "Otaku User"');
    await _safeAlter(db, 'ALTER TABLE users ADD COLUMN profile_image_path TEXT');
    await _safeAlter(db, 'ALTER TABLE users ADD COLUMN is_blocked INTEGER NOT NULL DEFAULT 0');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_anime(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        image_url TEXT NOT NULL,
        synopsis TEXT NOT NULL,
        genres TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _safeAlter(Database db, String sql) async {
    try {
      await db.execute(sql);
    } catch (_) {}
  }

  Future<void> _ensureAdminAccount() async {
    final db = _db!;
    final rows = await db.query('users', where: 'email = ?', whereArgs: ['admin@gmail.com'], limit: 1);
    if (rows.isNotEmpty) return;
    await db.insert('users', {
      'username': 'System Admin',
      'email': 'admin@gmail.com',
      'password_hash': _hashPassword('7264'),
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
      'is_blocked': 0,
    });
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode('anirec_salt::$password');
    return sha256.convert(bytes).toString();
  }

  Future<AppUser> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final normalizedEmail = email.trim().toLowerCase();
    final role = normalizedEmail == 'admin@gmail.com' && password == '7264' ? 'admin' : 'user';
    final id = await db.insert('users', {
      'username': username.trim().isEmpty ? 'Otaku User' : username.trim(),
      'email': normalizedEmail,
      'password_hash': _hashPassword(password),
      'role': role,
      'is_blocked': 0,
      'created_at': now,
    });
    final user = AppUser(
       id: id,
       username: normalizedEmail.split('@').first,
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
    if (user.isBlocked) return null;
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

  Future<void> updateUserProfile({
    required int userId,
    required String username,
    required String email,
    String? password,
    String? profileImagePath,
  }) async {
    final db = await database;
    final payload = <String, Object?>{
      'username': username.trim().isEmpty ? 'Otaku User' : username.trim(),
      'email': email.trim().toLowerCase(),
      'profile_image_path': profileImagePath,
    };
    if (password != null && password.trim().isNotEmpty) {
      payload['password_hash'] = _hashPassword(password.trim());
    }
    await db.update('users', payload, where: 'id = ?', whereArgs: [userId]);
  }

  Future<List<Map<String, Object?>>> adminUsersWithHashes({int limit = 100}) async {
    final db = await database;
    return db.query('users', orderBy: 'id DESC', limit: limit);
  }

  Future<void> blockUser(int userId, bool blocked) async {
    final db = await database;
    await db.update('users', {'is_blocked': blocked ? 1 : 0}, where: 'id = ?', whereArgs: [userId]);
    if (blocked) {
      final active = await getActiveUser();
      if (active?.id == userId) {
        await setActiveUserId(null);
      }
    }
  }

  Future<void> deleteUser(int userId) async {
    final db = await database;
    await db.delete('user_watchlist', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('search_logs', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
    final active = await getActiveUser();
    if (active?.id == userId) {
      await setActiveUserId(null);
    }
  }

  Future<AppUser> adminCreateUser({
    required String username,
    required String email,
    required String password,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('users', {
      'username': username.trim().isEmpty ? 'Otaku User' : username.trim(),
      'email': email.trim().toLowerCase(),
      'password_hash': _hashPassword(password.trim()),
      'role': 'user',
      'is_blocked': 0,
      'created_at': now,
    });
    return AppUser(
      id: id,
      username: username,
      email: email.trim().toLowerCase(),
      role: 'user',
      isBlocked: false,
      createdAt: DateTime.parse(now),
    );
  }

  Future<void> addCustomAnime({
    required String title,
    required String imageUrl,
    required String synopsis,
    required String genres,
  }) async {
    final db = await database;
    await db.insert('custom_anime', {
      'title': title.trim(),
      'image_url': imageUrl.trim(),
      'synopsis': synopsis.trim(),
      'genres': genres.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeCustomAnime(int id) async {
    final db = await database;
    await db.delete('custom_anime', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> listCustomAnime() async {
    final db = await database;
    return db.query('custom_anime', orderBy: 'id DESC');
  }

  Future<List<Map<String, Object?>>> topSearches({int limit = 8}) async {
    final db = await database;
    return db.rawQuery(
      'SELECT query, COUNT(*) as c FROM search_logs GROUP BY query ORDER BY c DESC LIMIT $limit',
    );
  }

  AppUser _rowToUser(Map<String, Object?> row) {
    return AppUser(
      id: row['id'] as int,
      username: (row['username'] ?? 'Otaku User').toString(),
      email: row['email'] as String,
      role: row['role'] as String,
      profileImagePath: row['profile_image_path']?.toString(),
      isBlocked: ((row['is_blocked'] ?? 0) as int) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
