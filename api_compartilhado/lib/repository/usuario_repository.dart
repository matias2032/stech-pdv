// lib/features/usuario/repository/usuario_repository.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

// ── Importa tudo de api_compartilhado (mesmo padrão do cliente_repository) ──
import 'package:api_compartilhado/models/usuario_model.dart';
import 'package:api_compartilhado/services/usuario_service.dart';

import '../../../core/database/daos/usuario_dao.dart';
import '../../../core/database/daos/sync_queue_dao.dart';

// Importa APENAS de core — evita o conflito com api_compartilhado
import '../../../core/connectivity/connectivity_service.dart';

class UsuarioRepository {
  UsuarioRepository({
    required UsuarioService      service,
    required UsuarioDao          dao,
    required SyncQueueDao        syncQueueDao,
    required ConnectivityService connectivity,
  })  : _service      = service,
        _dao          = dao,
        _syncQueueDao = syncQueueDao,
        _connectivity = connectivity;

  final UsuarioService      _service;
  final UsuarioDao          _dao;
  final SyncQueueDao        _syncQueueDao;
  final ConnectivityService _connectivity;

  static const _uuid = Uuid();

  // Helper local — substitui UsuarioModel._parseDate (era privado)
  static DateTime _parseDate(String? value) {
    if (value != null && value.isNotEmpty) {
      try { return DateTime.parse(value); } catch (_) {}
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ══════════════════════════════════════════════════════════════════
  // LEITURA
  // ══════════════════════════════════════════════════════════════════

  Future<List<UsuarioModel>> listarTodos({bool? ativo}) async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listar(ativo: ativo);
        await _dao.upsertAll(lista.map((u) => u.toLocalDb()).toList());
        return lista;
      } catch (e) {
        debugPrint('⚠️ UsuarioRepository.listarTodos HTTP falhou — usando cache: $e');
      }
    }
    if (ativo == true)  return (await _dao.getAtivos()).map(UsuarioModel.fromLocalDb).toList();
    if (ativo == false) return (await _dao.getInativos()).map(UsuarioModel.fromLocalDb).toList();
    return (await _dao.getAll()).map(UsuarioModel.fromLocalDb).toList();
  }

  Future<UsuarioModel?> buscarPorId(int id) async {
    if (_connectivity.isOnline) {
      try {
        final usuario = await _service.buscarPorId(id);
        await _dao.upsert(usuario.toLocalDb());
        return usuario;
      } catch (e) {
        debugPrint('⚠️ UsuarioRepository.buscarPorId HTTP falhou — usando cache: $e');
      }
    }
    final row = await _dao.getById(id);
    return row == null ? null : UsuarioModel.fromLocalDb(row);
  }

  // ══════════════════════════════════════════════════════════════════
  // ESCRITA
  // ══════════════════════════════════════════════════════════════════

  Future<UsuarioModel> criar(UsuarioRequestDTO dto) async {
    if (_connectivity.isOnline) {
      try {
        final usuario = await _service.criar(dto.toJson());
        await _dao.upsert(usuario.toLocalDb());
        return usuario;
      } catch (e) {
        debugPrint('⚠️ UsuarioRepository.criar HTTP falhou: $e');
        rethrow;
      }
    }

    final localId = _uuid.v4();
    final tempId  = -(DateTime.now().millisecondsSinceEpoch);
    final now     = DateTime.now();

    final usuarioLocal = UsuarioModel(
      id:            tempId,
      nome:          dto.nome,
      apelido:       dto.apelido,
      telefone:      dto.telefone,
      email:         dto.email,
      ativo:         true,
      idPerfil:      dto.idPerfil,
      nomePerfil:    'A sincronizar...',
      primeiraSenha: true,
      criadoEm:      now,
      atualizadoEm:  now,
      syncStatus:    'pending',
      localId:       localId,
    );

    await _dao.upsert(usuarioLocal.toLocalDb());
    await _syncQueueDao.enqueue(
      'usuario',
      'CREATE',
      {'localId': localId, ...dto.toJson()},
    );

    debugPrint('📥 UsuarioRepository — utilizador criado offline (localId: $localId)');
    return usuarioLocal;
  }

  Future<UsuarioModel> atualizar(int id, UsuarioRequestDTO dto) async {
    if (_connectivity.isOnline) {
      try {
        final usuario = await _service.atualizar(id, dto.toJson());
        await _dao.upsert(usuario.toLocalDb());
        return usuario;
      } catch (e) {
        debugPrint('⚠️ UsuarioRepository.atualizar HTTP falhou: $e');
        rethrow;
      }
    }

    final existente = await _dao.getById(id);
    final usuarioLocal = UsuarioModel(
      id:            id,
      nome:          dto.nome,
      apelido:       dto.apelido,
      telefone:      dto.telefone,
      email:         dto.email,
      ativo:         existente != null ? (existente['ativo'] as int? ?? 1) == 1 : true,
      idPerfil:      dto.idPerfil,
      nomePerfil:    existente?['nome_perfil'] as String? ?? 'Sem perfil',
      primeiraSenha: existente != null
          ? (existente['primeira_senha'] as int? ?? 1) == 1
          : true,
      criadoEm:     _parseDate(existente?['criado_em'] as String?),
      atualizadoEm: DateTime.now(),
      syncStatus:   'pending',
      localId:      existente?['local_id'] as String?,
    );

    await _dao.upsert(usuarioLocal.toLocalDb());
    await _syncQueueDao.enqueue(
      'usuario',
      'UPDATE',
      {'id': id, ...dto.toJson()},
    );

    debugPrint('📥 UsuarioRepository — utilizador $id actualizado offline');
    return usuarioLocal;
  }

  // ── Operações que requerem ligação activa ─────────────────────────

  Future<UsuarioModel> toggleAtivo(int id) async {
    if (!_connectivity.isOnline) {
      throw UsuarioServiceException(
        'Sem ligação. Não é possível alterar o estado do utilizador offline.',
      );
    }
    final atualizado = await _service.toggleAtivo(id);
    await _dao.upsert(atualizado.toLocalDb());
    return atualizado;
  }

  Future<void> resetarSenha(int id) async {
    if (!_connectivity.isOnline) {
      throw UsuarioServiceException(
        'Sem ligação. Não é possível reiniciar a senha offline.',
      );
    }
    await _service.resetarSenha(id);
  }

  Future<void> alterarSenha(int id, AlterarSenhaDTO dto) async {
    if (!_connectivity.isOnline) {
      throw UsuarioServiceException(
        'Sem ligação. Não é possível alterar a senha offline.',
      );
    }
    await _service.alterarSenha(id, dto.senhaAtual, dto.novaSenha);
  }
}