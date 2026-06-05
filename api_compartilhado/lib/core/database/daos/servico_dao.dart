// lib/core/database/daos/servico_dao.dart

import 'package:sqflite/sqflite.dart';
import '../local_database.dart';

class ServicoDao {
  Database get _db => LocalDatabase.instance.db;

  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _db.query('servico', orderBy: 'nome_servico ASC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getAtivos() async {
    final rows = await _db.query(
      'servico', where: 'ativo = ?', whereArgs: [1], orderBy: 'nome_servico ASC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _db.query(
      'servico', where: 'id = ?', whereArgs: [id], limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> getByLocalId(String localId) async {
    final rows = await _db.query(
      'servico', where: 'local_id = ?', whereArgs: [localId], limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<void> upsert(Map<String, dynamic> servico) async {
    await _db.insert('servico', servico,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertAll(List<Map<String, dynamic>> servicos) async {
    final batch = _db.batch();
    for (final s in servicos) {
      batch.insert('servico', s, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    await _db.delete('servico', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByLocalId(String localId) async {
    await _db.delete('servico', where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<void> marcarSynced(int id, {int? idReal}) async {
    final values = <String, dynamic>{'sync_status': 'synced'};
    if (idReal != null) values['id'] = idReal;
    await _db.update('servico', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPending() async {
    final rows = await _db.query('servico', where: "sync_status = 'pending'");
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> toggleAtivo(int id, {required int ativo}) async {
    await _db.update(
      'servico',
      {'ativo': ativo, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?', whereArgs: [id],
    );
  }
}