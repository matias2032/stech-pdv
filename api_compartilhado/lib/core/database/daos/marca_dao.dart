// lib/core/database/daos/marca_dao.dart

import 'package:sqflite/sqflite.dart';
import '../local_database.dart';

class MarcaDao {
  Database get _db => LocalDatabase.instance.db;

  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _db.query('marca', orderBy: 'nome_marca ASC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _db.query(
      'marca', where: 'id = ?', whereArgs: [id], limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> getByLocalId(String localId) async {
    final rows = await _db.query(
      'marca', where: 'local_id = ?', whereArgs: [localId], limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<void> upsert(Map<String, dynamic> marca) async {
    await _db.insert('marca', marca, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertAll(List<Map<String, dynamic>> marcas) async {
    final batch = _db.batch();
    for (final m in marcas) {
      batch.insert('marca', m, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    await _db.delete('marca', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByLocalId(String localId) async {
    await _db.delete('marca', where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<void> marcarSynced(int id, {int? idReal}) async {
    final values = <String, dynamic>{'sync_status': 'synced'};
    if (idReal != null) values['id'] = idReal;
    await _db.update('marca', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPending() async {
    final rows = await _db.query('marca', where: "sync_status = 'pending'");
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }
}