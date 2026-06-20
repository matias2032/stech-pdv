import 'package:api_compartilhado/api_compartilhado.dart';

import '../../../core/database/daos/fornecedor_dao.dart';
import '../../../core/database/daos/sync_queue_dao.dart';
import '../../../core/connectivity/connectivity_service.dart';
import 'package:flutter/foundation.dart';
class FornecedorRepository {
  final FornecedorService _service;
  final FornecedorDao _dao;
  final SyncQueueDao _syncQueueDao;
  final ConnectivityService _connectivityService;

  FornecedorRepository({
    FornecedorService? service,
    FornecedorDao? dao,
    SyncQueueDao? syncQueueDao,
    ConnectivityService? connectivityService,
  })  : _service = service ?? FornecedorService(),
        _dao = dao ?? FornecedorDao(),
        _syncQueueDao = syncQueueDao ?? SyncQueueDao(),
        _connectivityService =
            connectivityService ?? ConnectivityService.instance;

  // ─────────────────────────────────────────────────────────────
  // LISTAR
  // ─────────────────────────────────────────────────────────────

  Future<List<FornecedorModel>> listar() async {
    final online = _connectivityService.isOnline;

    if (online) {
      try {
        final fornecedoresRemotos = await _service.listar();

        await _dao.limpar();
        await _dao.inserirTodos(fornecedoresRemotos);

        return fornecedoresRemotos;
      } catch (_) {
        return _dao.listarTodos();
      }
    }

    return _dao.listarTodos();
  }

  // ─────────────────────────────────────────────────────────────
  // PESQUISAR
  // ─────────────────────────────────────────────────────────────

  Future<List<FornecedorModel>> pesquisar(String termo) async {
    final q = termo.trim();

    if (q.isEmpty) {
      return listar();
    }

    final online = _connectivityService.isOnline;

    if (online) {
      try {
        return await _service.pesquisar(q);
      } catch (_) {
        return _dao.pesquisar(q);
      }
    }

    return _dao.pesquisar(q);
  }

  // ─────────────────────────────────────────────────────────────
  // BUSCAR POR ID
  // ─────────────────────────────────────────────────────────────

  Future<FornecedorModel?> buscarPorId(int id) async {
    final online = _connectivityService.isOnline;

    if (online) {
      try {
        final fornecedor = await _service.buscarPorId(id);
        await _dao.salvarOuAtualizar(fornecedor);
        return fornecedor;
      } catch (_) {
        return _dao.buscarPorId(id);
      }
    }

    return _dao.buscarPorId(id);
  }

  // ─────────────────────────────────────────────────────────────
  // CRIAR
  // ─────────────────────────────────────────────────────────────

Future<FornecedorModel> criar(FornecedorModel fornecedor) async {
  _validarFornecedor(fornecedor);

  final online = _connectivityService.isOnline;

  debugPrint(
    '📡 FornecedorRepository — criar fornecedor; online=$online; contacto=${fornecedor.contacto}',
  );

  if (online) {
    try {
      debugPrint('🌐 FornecedorRepository — tentando criar fornecedor via API...');

      final criado = await _service.criar(fornecedor);

      debugPrint(
        '✅ FornecedorRepository — fornecedor criado via API id=${criado.id}',
      );

      await _dao.salvarOuAtualizar(criado);
      return criado;
    } catch (e, s) {
      debugPrint('⚠️ FornecedorRepository — API falhou, criando offline: $e');
      debugPrint('$s');

      return _criarOffline(fornecedor, tentarFlush: true);
    }
  }

  return _criarOffline(fornecedor, tentarFlush: false);
}

Future<FornecedorModel> _criarOffline(
  FornecedorModel fornecedor, {
  required bool tentarFlush,
}) async {
  final localId = await _dao.inserir(fornecedor);

  final fornecedorLocal = fornecedor.copyWith(id: localId);

  final payload = {
    'localId': localId.toString(),
    'nome': fornecedorLocal.nome,
    'email': fornecedorLocal.email,
    'nuit': fornecedorLocal.nuit,
    'contacto': fornecedorLocal.contacto,
    'morada': fornecedorLocal.morada,
  };

  await _syncQueueDao.enqueue(
    'fornecedor',
    'CREATE',
    payload,
  );

  debugPrint(
    '📥 FornecedorRepository — fornecedor criado offline localId=$localId',
  );
  debugPrint(
    '📦 FornecedorRepository — fornecedor/CREATE enviado para sync_queue: $payload',
  );

  if (tentarFlush && _connectivityService.isOnline) {
    debugPrint('🔁 FornecedorRepository — online, forçando flushQueue()');
    Future.microtask(() => SyncScheduler.instance.flushQueue());
  }

  return fornecedorLocal;
}

  // ─────────────────────────────────────────────────────────────
  // EDITAR
  // ─────────────────────────────────────────────────────────────

Future<FornecedorModel> editar({
  required int id,
  required FornecedorModel fornecedor,
}) async {
  _validarFornecedor(fornecedor);

  final fornecedorAtualizado = fornecedor.copyWith(id: id);
  final online = _connectivityService.isOnline;

  debugPrint(
    '📡 FornecedorRepository — editar fornecedor; online=$online; id=$id; contacto=${fornecedorAtualizado.contacto}',
  );

  if (online) {
    try {
      debugPrint('🌐 FornecedorRepository — tentando editar fornecedor via API...');

      final atualizado = await _service.editar(
        id: id,
        fornecedor: fornecedorAtualizado,
      );

      debugPrint(
        '✅ FornecedorRepository — fornecedor editado via API id=${atualizado.id}',
      );

      await _dao.salvarOuAtualizar(atualizado);
      return atualizado;
    } catch (e, s) {
      debugPrint(
        '⚠️ FornecedorRepository — API editar falhou, editando offline: $e',
      );
      debugPrint('$s');

      return _editarOffline(
        id: id,
        fornecedor: fornecedorAtualizado,
        tentarFlush: true,
      );
    }
  }

  return _editarOffline(
    id: id,
    fornecedor: fornecedorAtualizado,
    tentarFlush: false,
  );
}

Future<FornecedorModel> _editarOffline({
  required int id,
  required FornecedorModel fornecedor,
  required bool tentarFlush,
}) async {
  await _dao.atualizar(fornecedor);

  final payload = {
    'id': id,
    'localId': id.toString(),
    'nome': fornecedor.nome,
    'email': fornecedor.email,
    'nuit': fornecedor.nuit,
    'contacto': fornecedor.contacto,
    'morada': fornecedor.morada,
  };

  await _syncQueueDao.enqueue(
    'fornecedor',
    'UPDATE',
    payload,
  );

  debugPrint(
    '📝 FornecedorRepository — fornecedor editado offline id=$id',
  );
  debugPrint(
    '📦 FornecedorRepository — fornecedor/UPDATE enviado para sync_queue: $payload',
  );

  if (tentarFlush && _connectivityService.isOnline) {
    debugPrint('🔁 FornecedorRepository — online, forçando flushQueue() após UPDATE');
    Future.microtask(() => SyncScheduler.instance.flushQueue());
  }

  return fornecedor;
}

  // ─────────────────────────────────────────────────────────────
  // EXCLUIR
  // ─────────────────────────────────────────────────────────────

Future<void> excluir(int id) async {
  final online = _connectivityService.isOnline;

  debugPrint(
    '📡 FornecedorRepository — excluir fornecedor; online=$online; id=$id',
  );

  if (online) {
    try {
      debugPrint('🌐 FornecedorRepository — tentando excluir fornecedor via API...');

      await _service.excluir(id);
      await _dao.excluir(id);

      debugPrint(
        '✅ FornecedorRepository — fornecedor excluído via API id=$id',
      );

      return;
    } catch (e, s) {
      debugPrint(
        '⚠️ FornecedorRepository — API excluir falhou, excluindo offline: $e',
      );
      debugPrint('$s');

      await _excluirOffline(
        id,
        tentarFlush: true,
      );
      return;
    }
  }

  await _excluirOffline(
    id,
    tentarFlush: false,
  );
}
Future<void> _excluirOffline(
  int id, {
  required bool tentarFlush,
}) async {
  await _dao.excluir(id);

  final payload = {
    'id': id,
    'localId': id.toString(),
  };

  await _syncQueueDao.enqueue(
    'fornecedor',
    'DELETE',
    payload,
  );

  debugPrint(
    '🗑️ FornecedorRepository — fornecedor excluído offline id=$id',
  );
  debugPrint(
    '📦 FornecedorRepository — fornecedor/DELETE enviado para sync_queue: $payload',
  );

  if (tentarFlush && _connectivityService.isOnline) {
    debugPrint('🔁 FornecedorRepository — online, forçando flushQueue() após DELETE');
    Future.microtask(() => SyncScheduler.instance.flushQueue());
  }
}

  // ─────────────────────────────────────────────────────────────
  // VALIDAÇÃO
  // ─────────────────────────────────────────────────────────────

  void _validarFornecedor(FornecedorModel fornecedor) {
    if (fornecedor.contacto.trim().isEmpty) {
      throw Exception('Contacto é obrigatório.');
    }
  }
}