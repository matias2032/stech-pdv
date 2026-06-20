import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:sqflite/sqflite.dart';

import '../local_database.dart';

class FornecedorDao {
  Database get _db => LocalDatabase.instance.db;

  static const String table = 'fornecedor';

  // ─────────────────────────────────────────────────────────────
  // INSERIR
  // ─────────────────────────────────────────────────────────────

  Future<int> inserir(FornecedorModel fornecedor) async {
    return _db.insert(
      table,
      _toMap(fornecedor, incluirId: false),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // INSERIR TODOS
  // ─────────────────────────────────────────────────────────────

  Future<void> inserirTodos(List<FornecedorModel> fornecedores) async {
    final batch = _db.batch();

    for (final fornecedor in fornecedores) {
      batch.insert(
        table,
        _toMap(fornecedor, incluirId: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // ─────────────────────────────────────────────────────────────
  // SALVAR OU ATUALIZAR
  // ─────────────────────────────────────────────────────────────

  Future<void> salvarOuAtualizar(FornecedorModel fornecedor) async {
    await _db.insert(
      table,
      _toMap(fornecedor, incluirId: true),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LISTAR TODOS
  // ─────────────────────────────────────────────────────────────

  Future<List<FornecedorModel>> listarTodos() async {
    final rows = await _db.query(
      table,
      where: 'deleted = ?',
      whereArgs: [0],
      orderBy: 'nome COLLATE NOCASE ASC',
    );

    return rows.map(_fromMap).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // PESQUISAR
  // ─────────────────────────────────────────────────────────────

  Future<List<FornecedorModel>> pesquisar(String termo) async {
    final q = '%${termo.trim()}%';

    final rows = await _db.query(
      table,
      where: '''
        deleted = ?
        AND (
             nome     LIKE ? COLLATE NOCASE
          OR email    LIKE ? COLLATE NOCASE
          OR nuit     LIKE ? COLLATE NOCASE
          OR contacto LIKE ? COLLATE NOCASE
          OR morada   LIKE ? COLLATE NOCASE
        )
      ''',
      whereArgs: [0, q, q, q, q, q],
      orderBy: 'nome COLLATE NOCASE ASC',
    );

    return rows.map(_fromMap).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // BUSCAR POR ID
  // ─────────────────────────────────────────────────────────────

  Future<FornecedorModel?> buscarPorId(int id) async {
    final rows = await _db.query(
      table,
      where: 'id = ? AND deleted = ?',
      whereArgs: [id, 0],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return _fromMap(rows.first);
  }

  // ─────────────────────────────────────────────────────────────
  // ATUALIZAR
  // ─────────────────────────────────────────────────────────────

  Future<void> atualizar(FornecedorModel fornecedor) async {
    final id = fornecedor.id;

    if (id == null) {
      throw Exception('Não é possível atualizar fornecedor sem ID.');
    }

    await _db.update(
      table,
      _toMap(fornecedor, incluirId: false),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EXCLUIR
  // ─────────────────────────────────────────────────────────────

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

Future<void> deleteByLocalId(String localId) async {
  final id = int.tryParse(localId);

  if (id == null) return;

  await _db.delete(
    table,
    where: 'id = ?',
    whereArgs: [id],
  );
}

  // ─────────────────────────────────────────────────────────────
  // LIMPAR
  // ─────────────────────────────────────────────────────────────

  Future<void> limpar() async {
    await _db.delete(table);
  }

  // ─────────────────────────────────────────────────────────────
  // MAPPERS
  // ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _toMap(
    FornecedorModel fornecedor, {
    required bool incluirId,
  }) {
    final now = DateTime.now().toIso8601String();

    return {
      if (incluirId && fornecedor.id != null) 'id': fornecedor.id,
      'nome': _emptyToNull(fornecedor.nome),
      'email': _emptyToNull(fornecedor.email),
      'nuit': _emptyToNull(fornecedor.nuit),
      'contacto': fornecedor.contacto.trim(),
      'morada': _emptyToNull(fornecedor.morada),
      'deleted': 0,
      'updated_at': now,
    };
  }

  FornecedorModel _fromMap(Map<String, dynamic> map) {
    return FornecedorModel(
      id: _parseIntOpt(map['id']),
      nome: _parseStringOpt(map['nome']),
      email: _parseStringOpt(map['email']),
      nuit: _parseStringOpt(map['nuit']),
      contacto: map['contacto']?.toString() ?? '',
      morada: _parseStringOpt(map['morada']),
    );
  }

  int? _parseIntOpt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  String? _parseStringOpt(dynamic value) {
    if (value == null) return null;

    final texto = value.toString().trim();
    if (texto.isEmpty) return null;

    return texto;
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;

    final texto = value.trim();
    if (texto.isEmpty) return null;

    return texto;
  }
}