import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/error_code.dart';

class DatabaseService {
  static DatabaseService? _instance;
  Database? _db;

  DatabaseService._();

  static DatabaseService get instance => _instance ??= DatabaseService._();

  Future<Database> get database async => _db ??= await _initDb();

  Future<Database> _initDb() async {
    final dbPath = join(await getDatabasesPath(), 'fanuc_errors.db');
    final data = await rootBundle.load('assets/fanuc_errors.db');
    final bytes = data.buffer.asUint8List();
    await File(dbPath).writeAsBytes(bytes, flush: true);
    return openDatabase(dbPath, readOnly: true);
  }

  Future<List<ErrorCode>> search({
    String query = '',
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (query.isNotEmpty) {
      where.add('(code LIKE ? OR message LIKE ?)');
      args.addAll(['%$query%', '%$query%']);
    }
    if (type != null && type.isNotEmpty) {
      where.add('type = ?');
      args.add(type);
    }

    final whereStr = where.isEmpty ? null : where.join(' AND ');
    final rows = await db.query(
      'errors',
      where: whereStr,
      whereArgs: args.isEmpty ? null : args,
      limit: limit,
      offset: offset,
      orderBy: 'code',
    );
    return rows.map(ErrorCode.fromMap).toList();
  }

  Future<List<String>> getTypes() async {
    final db = await database;
    final rows = await db.rawQuery(
        "SELECT DISTINCT type FROM errors WHERE type != '' ORDER BY type");
    return rows.map((r) => r['type'] as String).toList();
  }

  Future<List<ErrorCode>> loadAll() async {
    final db = await database;
    final rows = await db.query('errors', orderBy: 'code');
    return rows.map(ErrorCode.fromMap).toList();
  }

  Future<int> count({String query = '', String? type}) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (query.isNotEmpty) {
      where.add('(code LIKE ? OR message LIKE ?)');
      args.addAll(['%$query%', '%$query%']);
    }
    if (type != null && type.isNotEmpty) {
      where.add('type = ?');
      args.add(type);
    }
    final whereStr = where.isEmpty ? null : where.join(' AND ');
    final result = await db.query(
      'errors',
      columns: ['COUNT(*) as c'],
      where: whereStr,
      whereArgs: args.isEmpty ? null : args,
    );
    return result.first['c'] as int;
  }
}
