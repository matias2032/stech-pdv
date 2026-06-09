// lib/core/database/daos/sync_queue_dao.dart

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../local_database.dart';
import 'package:flutter/foundation.dart';

/// Gere a fila de operações pendentes de sincronização com o backend.
class SyncQueueDao {
  Database get _db => LocalDatabase.instance.db;

  static const int _maxTentativas = 5;

  // ── Enfileirar nova operação ──────────────────────────────────────

  Future<void> enqueue(
    String entidade,
    String operacao,
    Map<String, dynamic> payload,
  ) async {
    await _db.insert('sync_queue', {
      'entidade':   entidade,
      'operacao':   operacao,
      'payload':    jsonEncode(payload),
      'tentativas': 0,
      'criado_em':  DateTime.now().toIso8601String(),
    });
  }

  // ── Buscar pendentes (tentativas < máximo) ────────────────────────

  Future<List<Map<String, dynamic>>> getPending() async {
    final rows = await _db.query(
      'sync_queue',
      where:   'tentativas < ?',
      whereArgs: [_maxTentativas],
      orderBy: 'id ASC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  // ── Incrementar tentativas após falha ─────────────────────────────

  Future<void> incrementarTentativas(int id) async {
    await _db.rawUpdate(
      'UPDATE sync_queue SET tentativas = tentativas + 1 WHERE id = ?',
      [id],
    );
  }

  // ── Apagar após sync bem-sucedido ─────────────────────────────────

  Future<void> delete(int id) async {
    await _db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // ── Apagar todas as operações de uma entidade (ex: logout) ────────

  Future<void> deleteByEntidade(String entidade) async {
    await _db.delete(
      'sync_queue',
      where:     'entidade = ?',
      whereArgs: [entidade],
    );
  }

Future<void> cancelarPorLocalId(String localId) async {
  await _db.rawDelete(
    r"DELETE FROM sync_queue WHERE json_extract(payload, '$.localId') = ?",
    [localId],
  );
}

Future<void> cancelarDeleteOrfao(String entidade, int idEntidade) async {
  await _db.rawDelete(
    r"DELETE FROM sync_queue WHERE entidade = ? AND operacao = 'DELETE' AND json_extract(payload, '$.id') = ?",
    [entidade, idEntidade],
  );
  debugPrint('🧹 SyncQueueDao — DELETE órfão removido ($entidade id=$idEntidade)');
}


  // ── Contar pendentes (para badge na UI) ───────────────────────────

  Future<int> countPending() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as total FROM sync_queue WHERE tentativas < ?',
      [_maxTentativas],
    );

    return (result.first['total'] as int?) ?? 0;
  }
}