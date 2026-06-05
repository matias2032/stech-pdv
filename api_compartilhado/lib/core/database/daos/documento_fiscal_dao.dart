// lib/core/database/daos/documento_fiscal_dao.dart

import 'package:sqflite/sqflite.dart';
import '../local_database.dart';

class DocumentoFiscalDao {
  Database get _db => LocalDatabase.instance.db;

  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _db.query(
      'documento_fiscal', orderBy: 'emitido_em DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _db.query(
      'documento_fiscal', where: 'id = ?', whereArgs: [id], limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> getByReferencia(String referencia) async {
    final rows = await _db.query(
      'documento_fiscal',
      where: 'referencia = ?',
      whereArgs: [referencia],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<List<Map<String, dynamic>>> getByPedido(int idPedido) async {
    final rows = await _db.query(
      'documento_fiscal',
      where: 'id_pedido = ?',
      whereArgs: [idPedido],
      orderBy: 'emitido_em DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getByTipo(int idTipoDoc) async {
    final rows = await _db.query(
      'documento_fiscal',
      where: 'id_tipo_doc = ?',
      whereArgs: [idTipoDoc],
      orderBy: 'emitido_em DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getAtivos() async {
    final rows = await _db.query(
      'documento_fiscal',
      where: 'anulado = 0',
      orderBy: 'emitido_em DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> upsert(Map<String, dynamic> doc) async {
    await _db.insert(
      'documento_fiscal', doc,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<Map<String, dynamic>> docs) async {
    final batch = _db.batch();
    for (final d in docs) {
      batch.insert(
        'documento_fiscal', d,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    await _db.delete('documento_fiscal', where: 'id = ?', whereArgs: [id]);
  }

  // documento_fiscal não tem localId (nunca criado offline)
  // mas mantemos a assinatura por consistência de padrão
  Future<void> deleteByLocalId(String localId) async {}

  Future<void> marcarSynced(int id, {int? idReal}) async {
    final values = <String, dynamic>{'sync_status': 'synced'};
    if (idReal != null) values['id'] = idReal;
    await _db.update(
      'documento_fiscal', values,
      where: 'id = ?', whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getPending() async {
    final rows = await _db.query(
      'documento_fiscal', where: "sync_status = 'pending'",
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }
}