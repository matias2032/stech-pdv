// lib/features/marca/repository/marca_repository.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:api_compartilhado/api_compartilhado.dart';
import '../../../core/database/daos/marca_dao.dart';
import '../../../core/database/daos/sync_queue_dao.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../services/marca_service.dart'; // MarcaService existente (não alterado)

class MarcaRepository {
  MarcaRepository({
    required MarcaService        service,
    required MarcaDao            dao,
    required SyncQueueDao        syncQueueDao,
    required ConnectivityService connectivity,
  })  : _service      = service,
        _dao          = dao,
        _syncQueueDao = syncQueueDao,
        _connectivity = connectivity;

  final MarcaService        _service;
  final MarcaDao            _dao;
  final SyncQueueDao        _syncQueueDao;
  final ConnectivityService _connectivity;

  static const _uuid = Uuid();

  // ── Leitura ───────────────────────────────────────────────────────

  Future<List<MarcaModel>> listarTodos() async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarMarcas();
   final models = lista.map((m) => m).toList();
        await _dao.upsertAll(models.map((m) => m.toLocalDb()).toList());
        return models;
      } catch (e) {
        debugPrint('⚠️ MarcaRepository.listarTodos HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getAll();
    return rows.map(MarcaModel.fromLocalDb).toList();
  }

  Future<MarcaModel?> buscarPorId(int id) async {
    if (_connectivity.isOnline) {
      try {
        final m = await _service.buscarMarcaPorId(id);
        final model = m; 
        await _dao.upsert(model.toLocalDb());
        return model;
      } catch (e) {
        debugPrint('⚠️ MarcaRepository.buscarPorId HTTP falhou — usando cache: $e');
      }
    }
    final row = await _dao.getById(id);
    return row == null ? null : MarcaModel.fromLocalDb(row);
  }

  // ── Escrita ───────────────────────────────────────────────────────

Future<MarcaModel> criar(MarcaRequestDTO dto) async {
 if (_connectivity.isOnline) {
    try {
      final model = await _service.criarMarca(dto); // ← directo, sem adaptador
      await _dao.upsert(model.toLocalDb());
      return model;
    } catch (e) {
      debugPrint('⚠️ MarcaRepository.criar HTTP falhou: $e');
      rethrow;
    }
  }

    final localId = _uuid.v4();
    final tempId  = -(DateTime.now().millisecondsSinceEpoch);
    final local   = MarcaModel(
      id:         tempId,
      nomeMarca:  dto.nomeMarca,
      syncStatus: 'pending',
      localId:    localId,
    );
    await _dao.upsert(local.toLocalDb());
    await _syncQueueDao.enqueue('marca', 'CREATE', {'localId': localId, ...dto.toJson()});
    debugPrint('📥 MarcaRepository — marca criada offline (localId: $localId)');
    return local;
  }

Future<MarcaModel> editar(int id, MarcaRequestDTO dto) async {
  if (_connectivity.isOnline) {
    try {
      final model = await _service.atualizarMarca(id, dto); // ← directo
      await _dao.upsert(model.toLocalDb());
      return model;
    } catch (e) {
      debugPrint('⚠️ MarcaRepository.editar HTTP falhou: $e');
      rethrow;
    }
  }

    final existente = await _dao.getById(id);
    final local = MarcaModel(
      id:         id,
      nomeMarca:  dto.nomeMarca,
      syncStatus: 'pending',
      localId:    existente?['local_id'] as String?,
    );
    await _dao.upsert(local.toLocalDb());
    await _syncQueueDao.enqueue('marca', 'UPDATE', {'id': id, ...dto.toJson()});
    debugPrint('📥 MarcaRepository — marca $id editada offline');
    return local;
  }

  Future<void> excluir(int id) async {
    if (_connectivity.isOnline) {
      try {
        await _service.deletarMarca(id);
        await _dao.delete(id);
        return;
      } catch (e) {
        debugPrint('⚠️ MarcaRepository.excluir HTTP falhou: $e');
        rethrow;
      }
    }
    await _syncQueueDao.enqueue('marca', 'DELETE', {'id': id});
    await _dao.delete(id);
    debugPrint('📥 MarcaRepository — marca $id marcada para exclusão offline');
  }

  /// Associar/desassociar categoria requer ligação (operação no backend).
  Future<void> associarCategoria(int idMarca, int idCategoria) async {
    if (_connectivity.isOffline) {
      throw Exception('Sem ligação — associação de categoria requer internet.');
    }
    await _service.associarCategoria(idMarca, idCategoria);
  }

  Future<void> desassociarCategoria(int idMarca, int idCategoria) async {
    if (_connectivity.isOffline) {
      throw Exception('Sem ligação — remoção de categoria requer internet.');
    }
    await _service.desassociarCategoria(idMarca, idCategoria);
  }

  // ── Adaptador para o MarcaService legado ─────────────────────────
  dynamic _toMarcaLegacy(MarcaRequestDTO dto) {
    // MarcaService recebe o objecto Marca legado; usamos o mesmo toJsonCreate
    // que o service já usa internamente — passamos um objecto mínimo.
    return _MarcaLegacyAdapter(dto.nomeMarca);
  }
}

/// Adaptador mínimo para o MarcaService legado que espera um objecto `Marca`.
class _MarcaLegacyAdapter {
  final String nomeMarca;
  _MarcaLegacyAdapter(this.nomeMarca);
  Map<String, dynamic> toJsonCreate() => {'nomeMarca': nomeMarca};
}

