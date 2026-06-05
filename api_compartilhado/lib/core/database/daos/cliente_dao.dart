// lib/core/database/daos/cliente_dao.dart

import 'package:sqflite/sqflite.dart';
import '../local_database.dart';

/// Acesso ao SQLite para a entidade cliente.
class ClienteDao {
  Database get _db => LocalDatabase.instance.db;

  // ── Buscar todos ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _db.query('cliente', orderBy: 'nome ASC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  // ── Buscar por ID ─────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _db.query(
      'cliente',
      where:     'id = ?',
      whereArgs: [id],
      limit:     1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  // ── Buscar por local_id (criados offline) ─────────────────────────

  Future<Map<String, dynamic>?> getByLocalId(String localId) async {
    final rows = await _db.query(
      'cliente',
      where:     'local_id = ?',
      whereArgs: [localId],
      limit:     1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  // ── Buscar por perfil ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getByPerfil(int idPerfil) async {
    final rows = await _db.query(
      'cliente',
      where:     'id_perfil = ?',
      whereArgs: [idPerfil],
      orderBy:   'nome ASC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  // ── Upsert único ──────────────────────────────────────────────────

  Future<void> upsert(Map<String, dynamic> cliente) async {
    await _db.insert(
      'cliente',
      cliente,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Upsert em lote (vindo do backend) ────────────────────────────

  Future<void> upsertAll(List<Map<String, dynamic>> clientes) async {
    final batch = _db.batch();
    for (final c in clientes) {
      batch.insert(
        'cliente',
        c,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Apagar por ID ─────────────────────────────────────────────────

  Future<void> delete(int id) async {
    await _db.delete('cliente', where: 'id = ?', whereArgs: [id]);
  }

  // ── Apagar por local_id ───────────────────────────────────────────

  Future<void> deleteByLocalId(String localId) async {
    await _db.delete(
      'cliente',
      where:     'local_id = ?',
      whereArgs: [localId],
    );
  }

  // ── Marcar como synced após confirmação do backend ────────────────

  Future<void> marcarSynced(int id, {int? idReal}) async {
    final values = <String, dynamic>{'sync_status': 'synced'};
    if (idReal != null) values['id'] = idReal;
    await _db.update(
      'cliente',
      values,
      where:     'id = ?',
      whereArgs: [id],
    );
  }

  // ── Buscar pendentes de sync ──────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPending() async {
    final rows = await _db.query(
      'cliente',
      where: "sync_status = 'pending'",
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }
}