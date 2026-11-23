import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

class CatalogDatabase {
  static Future<Database>? _database;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<Database> _open() async {
    final folder = await getDatabasesPath();
    return openDatabase(
      '$folder/rental_catalog.db',
      version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE catalog (url TEXT PRIMARY KEY, body TEXT NOT NULL)',
      ),
    );
  }

  static Future<void> save(Uri url, String body) async {
    if (!_supported) return;
    try {
      final db = await (_database ??= _open());
      await db.insert('catalog', {
        'url': url.toString(),
        'body': body,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (error) {
      debugPrint('SQLite write failed: $error');
    }
  }

  static Future<String?> read(Uri url) async {
    if (!_supported) return null;
    try {
      final db = await (_database ??= _open());
      final rows = await db.query(
        'catalog',
        columns: ['body'],
        where: 'url = ?',
        whereArgs: [url.toString()],
        limit: 1,
      );
      return rows.isEmpty ? null : rows.first['body'] as String;
    } catch (error) {
      debugPrint('SQLite read failed: $error');
      return null;
    }
  }

  static Future<({String body, bool offline})> get(
    Uri url, {
    bool useCache = true,
  }) async {
    http.Response? response;
    try {
      response = await http.get(url).timeout(const Duration(seconds: 8));
    } catch (_) {
      if (!useCache) rethrow;
    }
    if (response?.statusCode == 200) {
      final body = utf8.decode(response!.bodyBytes);
      if (useCache) await save(url, body);
      return (body: body, offline: false);
    }
    if (!useCache || (response != null && response.statusCode < 500)) {
      throw Exception('Không tải được dữ liệu danh mục');
    }
    final saved = await read(url);
    if (saved != null) return (body: saved, offline: true);
    throw Exception('Không tải được dữ liệu danh mục');
  }
}
