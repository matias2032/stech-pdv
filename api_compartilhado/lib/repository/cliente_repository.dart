// lib/repository/cliente_repository.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:api_compartilhado/api_config.dart';
import 'package:api_compartilhado/models/cliente_model.dart';
import 'package:api_compartilhado/models/cliente_model.dart';
import 'package:api_compartilhado/services/cliente_service.dart';
import '../../../core/database/daos/cliente_dao.dart';
import '../../../core/database/daos/sync_queue_dao.dart';
import '../../../core/connectivity/connectivity_service.dart';

/// Camada de repositório — implementa o padrão offline-first.
///
/// LEITURA:
///   1. Tenta HTTP
///   2. Sucesso → guarda no SQLite → retorna dados
///   3. Falha   → lê SQLite       → retorna dados em cache
///   4. Nunca lança excepção para o Provider
///
/// ESCRITA:
///   Online  → HTTP → sucesso → actualiza SQLite
///   Offline → SQLite (pending) + sync_queue → retorna modelo local
///
class ClienteRepository {
  ClienteRepository({
    required ClienteService      service,
    required ClienteDao          dao,
    required SyncQueueDao        syncQueueDao,
    required ConnectivityService connectivity,
  })  : _service      = service,
        _dao          = dao,
        _syncQueueDao = syncQueueDao,
        _connectivity = connectivity;

  final ClienteService      _service;
  final ClienteDao          _dao;
  final SyncQueueDao        _syncQueueDao;
  final ConnectivityService _connectivity;

  static const _uuid = Uuid();

  // ══════════════════════════════════════════════════════════════════
  // LEITURA
  // ══════════════════════════════════════════════════════════════════

  /// Lista todos os clientes.
  /// Online  → actualiza cache → retorna dados frescos.
  /// Offline → retorna cache local silenciosamente.
Future<List<ClienteModel>> listarTodos() async {
  debugPrint('🔌 isOnline=${_connectivity.isOnline} baseUrl=${ApiConfig.baseUrl}');
  
  if (_connectivity.isOnline) {
    try {
      final lista = await _service.listarTodos();
      debugPrint('✅ HTTP OK: ${lista.length} clientes');
      await _dao.upsertAll(lista.map((c) => c.toLocalDb()).toList());
      return lista;
    } catch (e) {
      debugPrint('❌ HTTP falhou: $e');
    }
  }
  
  final rows = await _dao.getAll();
  debugPrint('📦 Cache local: ${rows.length} clientes');
  return rows.map(ClienteModel.fromLocalDb).toList();
}

  /// Lista clientes filtrados por perfil.

Future<List<ClienteModel>> listarPorPerfil(int idPerfil) async {
  debugPrint('🔌 [Cliente] listarPorPerfil=$idPerfil isOnline=${_connectivity.isOnline}');
  if (_connectivity.isOnline) {
    try {
      final lista = await _service.listarPorPerfil(idPerfil);
      debugPrint('✅ [Cliente] listarPorPerfil HTTP OK: ${lista.length} registos');

      // Apaga do cache local os registos que o backend já não devolve (soft-deleted)
      final idsServidor = lista.map((c) => c.id).toSet();
      final cacheActual = await _dao.getByPerfil(idPerfil);
      for (final row in cacheActual) {
        final idLocal = row['id'] as int;
        if (!idsServidor.contains(idLocal)) {
          await _dao.delete(idLocal);
          debugPrint('🗑️ [Cliente] removido do cache local id=$idLocal (deleted no servidor)');
        }
      }

      await _dao.upsertAll(lista.map((c) => c.toLocalDb()).toList());
      return lista;
    } catch (e) {
      debugPrint('⚠️ [Cliente] listarPorPerfil HTTP falhou — usando cache: $e');
    }
  }
  final rows = await _dao.getByPerfil(idPerfil);
  debugPrint('📦 [Cliente] listarPorPerfil cache local: ${rows.length} registos');
  return rows.map(ClienteModel.fromLocalDb).toList();
}

  /// Pesquisa clientes por termo.
  Future<List<ClienteModel>> pesquisar(String termo) async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.pesquisar(termo);
        // Não actualiza cache em pesquisa — apenas retorna resultado
        return lista;
      } catch (e) {
        debugPrint('⚠️ ClienteRepository.pesquisar HTTP falhou — pesquisa local: $e');
      }
    }
    // Fallback: pesquisa local simples
    final rows = await _dao.getAll();
    final termoLower = termo.toLowerCase();
    return rows
        .map(ClienteModel.fromLocalDb)
        .where((c) =>
            (c.nome?.toLowerCase().contains(termoLower) ?? false) ||
            (c.apelido?.toLowerCase().contains(termoLower) ?? false) ||
            (c.contacto?.toLowerCase().contains(termoLower) ?? false) ||
            (c.email?.toLowerCase().contains(termoLower) ?? false))
        .toList();
  }

  /// Busca cliente por ID.
  Future<ClienteModel?> buscarPorId(int id) async {
    if (_connectivity.isOnline) {
      try {
        final cliente = await _service.buscarPorId(id);
        await _dao.upsert(cliente.toLocalDb());
        return cliente;
      } catch (e) {
        debugPrint('⚠️ ClienteRepository.buscarPorId HTTP falhou — usando cache: $e');
      }
    }
    final row = await _dao.getById(id);
    return row == null ? null : ClienteModel.fromLocalDb(row);
  }

  // ══════════════════════════════════════════════════════════════════
  // ESCRITA
  // ══════════════════════════════════════════════════════════════════

  /// Cria um novo cliente.
  /// Online  → HTTP → guarda resultado no SQLite.
  /// Offline → cria localmente com ID temporário → enfileira sync.
  Future<ClienteModel> criar(ClienteRequestDTO dto) async {
if (_connectivity.isOnline) {
  try {
    final cliente = await _service.criar(dto);
    await _dao.upsert(cliente.toLocalDb());
    return cliente;
  } catch (e) {
    debugPrint('⚠️ ClienteRepository.criar HTTP falhou: $e');
    rethrow;
  }
}

    // ── Modo offline: criar localmente ────────────────────────────
    final localId   = _uuid.v4();
    final tempId    = -(DateTime.now().millisecondsSinceEpoch); // ID negativo temporário
    final clienteLocal = ClienteModel(
      id:         tempId,
      nome:       dto.nome,
      apelido:    dto.apelido,
      email:      dto.email,
      nuit:       dto.nuit,
      contacto:   dto.contacto,
      morada:     dto.morada,
      idPerfil:   dto.idPerfil,
      nomePerfil: 'A sincronizar...',
      syncStatus: 'pending',
      localId:    localId,
    );

    await _dao.upsert(clienteLocal.toLocalDb());
    await _syncQueueDao.enqueue(
      'cliente',
      'CREATE',
      {'localId': localId, ...dto.toJson()},
    );

    debugPrint('📥 ClienteRepository — cliente criado offline (localId: $localId)');
    return clienteLocal;
  }

  /// Edita um cliente existente.
  Future<ClienteModel> editar(int id, ClienteRequestDTO dto) async {
if (_connectivity.isOnline) {
  try {
    final cliente = await _service.editar(id, dto);
    await _dao.upsert(cliente.toLocalDb());
    debugPrint('✅ [Cliente] editado online id=$id');
    return cliente;
  } catch (e) {
    debugPrint('⚠️ [Cliente] editar HTTP falhou: $e');
    rethrow;
  }
}

    // ── Modo offline: actualizar localmente ───────────────────────
    final existente = await _dao.getById(id);
    final clienteLocal = ClienteModel(
      id:         id,
      nome:       dto.nome,
      apelido:    dto.apelido,
      email:      dto.email,
      nuit:       dto.nuit,
      contacto:   dto.contacto,
      morada:     dto.morada,
      idPerfil:   dto.idPerfil,
      nomePerfil: existente?['nome_perfil'] as String? ?? 'Sem perfil',
      syncStatus: 'pending',
      localId:    existente?['local_id'] as String?,
    );

    await _dao.upsert(clienteLocal.toLocalDb());
    await _syncQueueDao.enqueue(
      'cliente',
      'UPDATE',
      {'id': id, ...dto.toJson()},
    );

    debugPrint('📥 ClienteRepository — cliente $id editado offline');
    return clienteLocal;
  }

  /// Exclui um cliente.
Future<void> excluir(int id) async {
if (_connectivity.isOnline) {
  try {
    await _service.excluir(id);
    await _dao.delete(id);
    debugPrint('✅ [Cliente] excluído online id=$id');
    return;
  } catch (e) {
    debugPrint('⚠️ [Cliente] excluir HTTP falhou: $e');
    rethrow;
  }
}

    // ── Modo offline: marcar como pending delete ──────────────────
    await _syncQueueDao.enqueue('cliente', 'DELETE', {'id': id});
    await _dao.delete(id); // Remove localmente (optimistic)
    debugPrint('📥 ClienteRepository — cliente $id marcado para exclusão offline');
  }
}