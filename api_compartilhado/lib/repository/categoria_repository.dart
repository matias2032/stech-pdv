// lib/features/categoria/repository/categoria_repository.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:api_compartilhado/api_compartilhado.dart';
import '../../../core/database/daos/categoria_dao.dart';
import '../../../core/database/daos/sync_queue_dao.dart';
import '../../../core/connectivity/connectivity_service.dart';

class CategoriaRepository {
  CategoriaRepository({
    required CategoriaService    service,
    required CategoriaDao        dao,
    required SyncQueueDao        syncQueueDao,
    required ConnectivityService connectivity,
  })  : _service      = service,
        _dao          = dao,
        _syncQueueDao = syncQueueDao,
        _connectivity = connectivity;

  final CategoriaService    _service;
  final CategoriaDao        _dao;
  final SyncQueueDao        _syncQueueDao;
  final ConnectivityService _connectivity;

  static const _uuid = Uuid();

  // ── Leitura ───────────────────────────────────────────────────────

  Future<List<CategoriaModel>> listarTodos() async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarCategorias();
        await _dao.upsertAll(lista.map((c) => c.toLocalDb()).toList());
        return lista;
      } catch (e) {
        debugPrint('⚠️ CategoriaRepository.listarTodos HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getAll();
    return rows.map(CategoriaModel.fromLocalDb).toList();
  }

  Future<CategoriaModel?> buscarPorId(int id) async {
    if (_connectivity.isOnline) {
      try {
        final c = await _service.buscarCategoriaPorId(id);
        await _dao.upsert(c.toLocalDb());
        return c;
      } catch (e) {
        debugPrint('⚠️ CategoriaRepository.buscarPorId HTTP falhou — usando cache: $e');
      }
    }
    final row = await _dao.getById(id);
    return row == null ? null : CategoriaModel.fromLocalDb(row);
  }

  // ── Escrita ───────────────────────────────────────────────────────

  Future<CategoriaModel> criar(CategoriaRequestDTO dto) async {
    if (_connectivity.isOnline) {
      try {
        final c = await _service.criarCategoria(dto);
        await _dao.upsert(c.toLocalDb());
        return c;
      } catch (e) {
        debugPrint('⚠️ CategoriaRepository.criar HTTP falhou: $e');
        rethrow;
      }
    }

    final localId = _uuid.v4();
    final tempId  = -(DateTime.now().millisecondsSinceEpoch);
    final local   = CategoriaModel(
      id:            tempId,
      nomeCategoria: dto.nomeCategoria,
      descricao:     dto.descricao,
      syncStatus:    'pending',
      localId:       localId,
    );
    await _dao.upsert(local.toLocalDb());
    await _syncQueueDao.enqueue('categoria', 'CREATE',
        {'localId': localId, ...dto.toJson()});
    debugPrint('📥 CategoriaRepository — categoria criada offline (localId: $localId)');
    return local;
  }

  Future<CategoriaModel> editar(int id, CategoriaRequestDTO dto) async {
    if (_connectivity.isOnline) {
      try {
        final c = await _service.atualizarCategoria(id, dto);
        await _dao.upsert(c.toLocalDb());
        return c;
      } catch (e) {
        debugPrint('⚠️ CategoriaRepository.editar HTTP falhou: $e');
        rethrow;
      }
    }

    final existente = await _dao.getById(id);
    final local = CategoriaModel(
      id:            id,
      nomeCategoria: dto.nomeCategoria,
      descricao:     dto.descricao,
      syncStatus:    'pending',
      localId:       existente?['local_id'] as String?,
    );
    await _dao.upsert(local.toLocalDb());
    await _syncQueueDao.enqueue('categoria', 'UPDATE', {'id': id, ...dto.toJson()});
    debugPrint('📥 CategoriaRepository — categoria $id editada offline');
    return local;
  }

  Future<void> excluir(int id) async {
    if (_connectivity.isOnline) {
      try {
        await _service.deletarCategoria(id);
        await _dao.delete(id);
        return;
      } catch (e) {
        debugPrint('⚠️ CategoriaRepository.excluir HTTP falhou: $e');
        rethrow;
      }
    }
    await _syncQueueDao.enqueue('categoria', 'DELETE', {'id': id});
    await _dao.delete(id);
    debugPrint('📥 CategoriaRepository — categoria $id marcada para exclusão offline');
  }

  /// Requer ligação — operação relacional gerida pelo backend.
  Future<void> associarMarca(int idCategoria, int idMarca) async {
    if (_connectivity.isOffline) {
      throw CategoriaServiceException('Sem ligação — associação de marca requer internet.');
    }
    await _service.associarMarca(idCategoria, idMarca);
  }

  Future<void> desassociarMarca(int idCategoria, int idMarca) async {
    if (_connectivity.isOffline) {
      throw CategoriaServiceException('Sem ligação — remoção de marca requer internet.');
    }
    await _service.desassociarMarca(idCategoria, idMarca);
  }
}