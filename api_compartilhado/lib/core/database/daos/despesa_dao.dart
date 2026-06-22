import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:sqflite/sqflite.dart';

import '../local_database.dart';

class DespesaDao {
  Database get _db => LocalDatabase.instance.db;

  static const String table = 'despesa';

  Future<int> inserir(DespesaModel despesa) async {
    return _db.insert(
      table,
      _toMap(despesa, incluirId: false),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> inserirTodos(List<DespesaModel> despesas) async {
    final batch = _db.batch();

    for (final despesa in despesas) {
      batch.insert(
        table,
        _toMap(despesa, incluirId: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> salvarOuAtualizar(DespesaModel despesa) async {
    await _db.insert(
      table,
      _toMap(despesa, incluirId: true),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DespesaModel>> listarTodos() async {
    final rows = await _db.query(
      table,
      where: 'deleted = ?',
      whereArgs: [0],
      orderBy: 'datetime(data_despesa) DESC',
    );

    return rows.map(_fromMap).toList();
  }

  Future<List<DespesaModel>> listarPorFornecedor(int idFornecedor) async {
    final rows = await _db.query(
      table,
      where: 'id_fornecedor = ? AND deleted = ?',
      whereArgs: [idFornecedor, 0],
      orderBy: 'datetime(data_despesa) DESC',
    );

    return rows.map(_fromMap).toList();
  }

  Future<List<DespesaModel>> listarPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final rows = await _db.query(
      table,
      where: '''
        deleted = ?
        AND datetime(data_despesa) BETWEEN datetime(?) AND datetime(?)
      ''',
      whereArgs: [
        0,
        inicio.toIso8601String(),
        fim.toIso8601String(),
      ],
      orderBy: 'datetime(data_despesa) DESC',
    );

    return rows.map(_fromMap).toList();
  }

    Future<void> upsertAll(List<Map<String, dynamic>> despesas) async {
    final batch = _db.batch();
    for (final d in despesas) {
      batch.insert('despesa', d, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }


  Future<DespesaModel?> buscarPorId(int id) async {
    final rows = await _db.query(
      table,
      where: 'id = ? AND deleted = ?',
      whereArgs: [id, 0],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return _fromMap(rows.first);
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final rows = await _db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> atualizar(DespesaModel despesa) async {
    final id = despesa.idDespesa;

    if (id == null) {
      throw Exception('Não é possível atualizar despesa sem ID.');
    }

    await _db.update(
      table,
      _toMap(despesa, incluirId: false),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> excluir(int id) async {
    await _db.update(
      table,
      {
        'deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteByLocalId(String localId) async {
    final id = int.tryParse(localId);
    if (id == null) return;

    await _db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> limpar() async {
    await _db.delete(table);
  }

  Map<String, dynamic> _toMap(
    DespesaModel despesa, {
    required bool incluirId,
  }) {
    final now = DateTime.now().toIso8601String();

    return {
      if (incluirId && despesa.idDespesa != null) 'id': despesa.idDespesa,
      'id_fornecedor': despesa.idFornecedor,
      'nome_fornecedor': despesa.nomeFornecedor,
      'nuit_fornecedor': despesa.nuitFornecedor,
      'descricao': despesa.descricao.trim(),
      'valor_gasto': despesa.valorGasto,
      'data_despesa':
          despesa.dataDespesa?.toIso8601String() ?? now,
      'deleted': despesa.deleted ? 1 : 0,
      'sync_status': despesa.syncStatus ?? 'synced',
      'updated_at': now,
    };
  }

  DespesaModel _fromMap(Map<String, dynamic> map) {
    return DespesaModel(
      idDespesa: _parseIntOpt(map['id']),
      idFornecedor: _parseIntOpt(map['id_fornecedor']),
      nomeFornecedor: _parseStringOpt(map['nome_fornecedor']),
      nuitFornecedor: _parseStringOpt(map['nuit_fornecedor']),
      descricao: map['descricao']?.toString() ?? '',
      valorGasto: _parseDouble(map['valor_gasto']),
      dataDespesa: _parseDateOpt(map['data_despesa']),
      deleted: _parseBool(map['deleted']),
      syncStatus: _parseStringOpt(map['sync_status']),
    );
  }

  int? _parseIntOpt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  DateTime? _parseDateOpt(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String? _parseStringOpt(dynamic value) {
    if (value == null) return null;
    final texto = value.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value == 1;
    return value.toString().toLowerCase() == 'true';
  }
}