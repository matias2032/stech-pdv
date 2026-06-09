// lib/core/database/daos/produto_dao.dart

import 'package:sqflite/sqflite.dart';
import '../local_database.dart';

class ProdutoDao {
  Database get _db => LocalDatabase.instance.db;

  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _db.query('produto', orderBy: 'nome_produto ASC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getAtivos() async {
    final rows = await _db.query(
      'produto',
      where:     'ativo = ?',
      whereArgs: [1],
      orderBy:   'nome_produto ASC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _db.query(
      'produto', where: 'id = ?', whereArgs: [id], limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> getByLocalId(String localId) async {
    final rows = await _db.query(
      'produto', where: 'local_id = ?', whereArgs: [localId], limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<void> upsert(Map<String, dynamic> produto) async {
    await _db.insert('produto', produto,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertAll(List<Map<String, dynamic>> produtos) async {
    final batch = _db.batch();
    for (final p in produtos) {
      batch.insert('produto', p, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    await _db.delete('produto', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByLocalId(String localId) async {
    await _db.delete('produto', where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<void> marcarSynced(int id, {int? idReal}) async {
    final values = <String, dynamic>{'sync_status': 'synced'};
    if (idReal != null) values['id'] = idReal;
    await _db.update('produto', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPending() async {
    final rows = await _db.query('produto', where: "sync_status = 'pending'");
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> toggleAtivo(int id, {required int ativo}) async {
    await _db.update(
      'produto',
      {'ativo': ativo, 'updated_at': DateTime.now().toIso8601String()},
      where:     'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> decrementarEstoque(int idProduto, int quantidade) async {
  await _db.rawUpdate(
    'UPDATE produto SET quantidade_estoque = MAX(0, quantidade_estoque - ?) WHERE id = ?',
    [quantidade, idProduto],
  );
}

Future<void> incrementarEstoque(int idProduto, int quantidade) async {
  await _db.rawUpdate(
    'UPDATE produto SET quantidade_estoque = quantidade_estoque + ? WHERE id = ?',
    [quantidade, idProduto],
  );
}
}