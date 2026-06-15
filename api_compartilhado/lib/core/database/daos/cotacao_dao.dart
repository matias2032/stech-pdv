// lib/core/database/daos/cotacao_dao.dart

import 'package:sqflite/sqflite.dart';
import '../local_database.dart';

class CotacaoDao {
  Database get _db => LocalDatabase.instance.db;

  // ══════════════════════════════════════════════════════════════════
  // COTAÇÃO
  // ══════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _db.query('cotacao', orderBy: 'created_at DESC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  /// Equivalente a `cotacaoRepository.findAllAtivas()` no backend —
  /// exclui registos marcados como eliminados (soft delete).
  Future<List<Map<String, dynamic>>> getAllAtivas() async {
    final rows = await _db.query(
      'cotacao',
      where: 'deleted = 0',
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _db.query(
      'cotacao', where: 'id = ?', whereArgs: [id], limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> getByLocalId(String localId) async {
    final rows = await _db.query(
      'cotacao', where: 'local_id = ?', whereArgs: [localId], limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<List<Map<String, dynamic>>> getByStatus(String status) async {
    final rows = await _db.query(
      'cotacao',
      where: 'status_cotacao = ? AND deleted = 0',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getByCliente(int idCliente) async {
    final rows = await _db.query(
      'cotacao',
      where: 'id_cliente = ? AND deleted = 0',
      whereArgs: [idCliente],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getByUsuario(int idUsuario) async {
    final rows = await _db.query(
      'cotacao',
      where: 'id_usuario = ? AND deleted = 0',
      whereArgs: [idUsuario],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> upsert(Map<String, dynamic> cotacao) async {
    await _db.insert(
      'cotacao', cotacao, conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<Map<String, dynamic>> cotacoes) async {
    final batch = _db.batch();
    for (final c in cotacoes) {
      batch.insert('cotacao', c, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    await _db.delete('cotacao', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByLocalId(String localId) async {
    await _db.delete('cotacao', where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<void> marcarSynced(int id, {int? idReal}) async {
    final values = <String, dynamic>{'sync_status': 'synced'};
    if (idReal != null) values['id'] = idReal;
    await _db.update('cotacao', values, where: 'id = ?', whereArgs: [id]);
  }

  /// Soft delete local — espelha `Cotacao.deleted` no backend.
  Future<void> marcarDeletada(int id, {String syncStatus = 'synced'}) async {
    await _db.update(
      'cotacao',
      {
        'deleted':     1,
        'sync_status': syncStatus,
        'updated_at':  DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getPending() async {
    final rows = await _db.query('cotacao', where: "sync_status = 'pending'");
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  // ══════════════════════════════════════════════════════════════════
  // COTACAO_ITEM_PRODUTO
  // ══════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getItensProdutoPorCotacao(int idCotacao) async {
    final rows = await _db.query(
      'cotacao_item_produto',
      where: 'id_cotacao = ?',
      whereArgs: [idCotacao],
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>?> getItemProdutoPorId(int idItem, int idCotacao) async {
    final rows = await _db.query(
      'cotacao_item_produto',
      where: 'id = ? AND id_cotacao = ?',
      whereArgs: [idItem, idCotacao],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  /// Procura um item de produto já existente na cotação para o mesmo
  /// `idProduto` — espelha o `findByCotacaoIdAndProdutoIdProduto` do backend,
  /// usado para incrementar quantidade em vez de duplicar a linha.
  Future<Map<String, dynamic>?> getItemProdutoPorProduto(int idCotacao, int idProduto) async {
    final rows = await _db.query(
      'cotacao_item_produto',
      where: 'id_cotacao = ? AND id_produto = ?',
      whereArgs: [idCotacao, idProduto],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<void> upsertItemProduto(Map<String, dynamic> item) async {
    await _db.insert(
      'cotacao_item_produto', item, conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAllItensProduto(List<Map<String, dynamic>> itens) async {
    final batch = _db.batch();
    for (final i in itens) {
      batch.insert(
        'cotacao_item_produto', i, conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteItemProduto(int idItem) async {
    await _db.delete('cotacao_item_produto', where: 'id = ?', whereArgs: [idItem]);
  }

  Future<void> deleteItensProdutoPorCotacao(int idCotacao) async {
    await _db.delete(
      'cotacao_item_produto', where: 'id_cotacao = ?', whereArgs: [idCotacao],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // COTACAO_ITEM_SERVICO
  // ══════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getItensServicoPorCotacao(int idCotacao) async {
    final rows = await _db.query(
      'cotacao_item_servico',
      where: 'id_cotacao = ?',
      whereArgs: [idCotacao],
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>?> getItemServicoPorId(int idItem, int idCotacao) async {
    final rows = await _db.query(
      'cotacao_item_servico',
      where: 'id = ? AND id_cotacao = ?',
      whereArgs: [idItem, idCotacao],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  /// Espelha `findByCotacaoIdAndServicoIdServico` do backend, usado para
  /// incrementar quantidade em vez de duplicar a linha.
  Future<Map<String, dynamic>?> getItemServicoPorServico(int idCotacao, int idServico) async {
    final rows = await _db.query(
      'cotacao_item_servico',
      where: 'id_cotacao = ? AND id_servico = ?',
      whereArgs: [idCotacao, idServico],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<void> upsertItemServico(Map<String, dynamic> item) async {
    await _db.insert(
      'cotacao_item_servico', item, conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAllItensServico(List<Map<String, dynamic>> itens) async {
    final batch = _db.batch();
    for (final i in itens) {
      batch.insert(
        'cotacao_item_servico', i, conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteItemServico(int idItem) async {
    await _db.delete('cotacao_item_servico', where: 'id = ?', whereArgs: [idItem]);
  }

  Future<void> deleteItensServicoPorCotacao(int idCotacao) async {
    await _db.delete(
      'cotacao_item_servico', where: 'id_cotacao = ?', whereArgs: [idCotacao],
    );
  }
}