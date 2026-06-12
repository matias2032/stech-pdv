// lib/core/database/daos/pedido_dao.dart

import 'package:sqflite/sqflite.dart';
import '../local_database.dart';

class PedidoDao {
  Database get _db => LocalDatabase.instance.db;

  // ══════════════════════════════════════════════════════════════════
  // PEDIDO
  // ══════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _db.query('pedido', orderBy: 'data_pedido DESC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _db.query(
      'pedido', where: 'id = ?', whereArgs: [id], limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> getByLocalId(String localId) async {
    final rows = await _db.query(
      'pedido', where: 'local_id = ?', whereArgs: [localId], limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<List<Map<String, dynamic>>> getByStatus(String status) async {
    final rows = await _db.query(
      'pedido',
      where: 'status_pedido = ?',
      whereArgs: [status],
      orderBy: 'data_pedido DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getByUsuario(int idUsuario) async {
    final rows = await _db.query(
      'pedido',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'data_pedido DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getByUsuarioEStatus(
    int idUsuario,
    String status,
  ) async {
    final rows = await _db.query(
      'pedido',
      where: 'id_usuario = ? AND status_pedido = ?',
      whereArgs: [idUsuario, status],
      orderBy: 'data_pedido DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> upsert(Map<String, dynamic> pedido) async {
    await _db.insert(
      'pedido', pedido, conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<Map<String, dynamic>> pedidos) async {
    final batch = _db.batch();
    for (final p in pedidos) {
      batch.insert('pedido', p, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    await _db.delete('pedido', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByLocalId(String localId) async {
    await _db.delete('pedido', where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<void> marcarSynced(int id, {int? idReal}) async {
    final values = <String, dynamic>{'sync_status': 'synced'};
    if (idReal != null) values['id'] = idReal;
    await _db.update('pedido', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPending() async {
    final rows = await _db.query('pedido', where: "sync_status = 'pending'");
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  // ══════════════════════════════════════════════════════════════════
  // ITEM_PEDIDO (produtos)
  // ══════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getItensByPedido(int idPedido) async {
    final rows = await _db.query(
      'item_pedido',
      where: 'id_pedido = ?',
      whereArgs: [idPedido],
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> upsertItem(Map<String, dynamic> item) async {
    await _db.insert(
      'item_pedido', item, conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAllItens(List<Map<String, dynamic>> itens) async {
    final batch = _db.batch();
    for (final i in itens) {
      batch.insert('item_pedido', i, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteItensByPedido(int idPedido) async {
    await _db.delete('item_pedido', where: 'id_pedido = ?', whereArgs: [idPedido]);
  }

  // ══════════════════════════════════════════════════════════════════
  // ITEM_PEDIDO_SERVICO (serviços)
  // ══════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getItensServicoPorPedido(int idPedido) async {
    final rows = await _db.query(
      'item_pedido_servico',
      where: 'id_pedido = ?',
      whereArgs: [idPedido],
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> upsertItemServico(Map<String, dynamic> item) async {
    await _db.insert(
      'item_pedido_servico', item, conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAllItensServico(List<Map<String, dynamic>> itens) async {
    final batch = _db.batch();
    for (final i in itens) {
      batch.insert(
        'item_pedido_servico', i, conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteItensServicoPorPedido(int idPedido) async {
    await _db.delete(
      'item_pedido_servico', where: 'id_pedido = ?', whereArgs: [idPedido],
    );
  }
}