import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:flutter/foundation.dart';

class DespesaRepository {
  final DespesaService _service;
  final DespesaDao _dao;
  final SyncQueueDao _syncQueueDao;
  final ConnectivityService _connectivityService;

  DespesaRepository({
    DespesaService? service,
    DespesaDao? dao,
    SyncQueueDao? syncQueueDao,
    ConnectivityService? connectivityService,
  })  : _service = service ?? DespesaService(),
        _dao = dao ?? DespesaDao(),
        _syncQueueDao = syncQueueDao ?? SyncQueueDao(),
        _connectivityService =
            connectivityService ?? ConnectivityService.instance;

  Future<List<DespesaModel>> listar() async {
    final online = _connectivityService.isOnline;

    if (online) {
      try {
        final remotas = await _service.listar();
        await _dao.limpar();
        await _dao.inserirTodos(remotas);
        return remotas;
      } catch (_) {
        return _dao.listarTodos();
      }
    }

    return _dao.listarTodos();
  }

  Future<DespesaModel?> buscarPorId(int id) async {
    final online = _connectivityService.isOnline;

    if (online) {
      try {
        final despesa = await _service.buscarPorId(id);
        await _dao.salvarOuAtualizar(despesa);
        return despesa;
      } catch (_) {
        return _dao.buscarPorId(id);
      }
    }

    return _dao.buscarPorId(id);
  }

  Future<List<DespesaModel>> listarPorFornecedor(int idFornecedor) async {
    final online = _connectivityService.isOnline;

    if (online) {
      try {
        return await _service.listarPorFornecedor(idFornecedor);
      } catch (_) {
        return _dao.listarPorFornecedor(idFornecedor);
      }
    }

    return _dao.listarPorFornecedor(idFornecedor);
  }

  Future<List<DespesaModel>> listarPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final online = _connectivityService.isOnline;

    if (online) {
      try {
        return await _service.listarPorPeriodo(
          inicio: inicio,
          fim: fim,
        );
      } catch (_) {
        return _dao.listarPorPeriodo(
          inicio: inicio,
          fim: fim,
        );
      }
    }

    return _dao.listarPorPeriodo(
      inicio: inicio,
      fim: fim,
    );
  }

  Future<DespesaModel> criar(DespesaModel despesa) async {
    _validarDespesa(despesa);

    final online = _connectivityService.isOnline;

    debugPrint(
      '📡 DespesaRepository — criar despesa; online=$online; descricao=${despesa.descricao}',
    );

    if (online) {
      try {
        final criada = await _service.criar(despesa);
        await _dao.salvarOuAtualizar(criada);
        return criada;
      } catch (e, s) {
        debugPrint('⚠️ DespesaRepository — API falhou, criando offline: $e');
        debugPrint('$s');

        return _criarOffline(despesa, tentarFlush: true);
      }
    }

    return _criarOffline(despesa, tentarFlush: false);
  }

  Future<DespesaModel> _criarOffline(
    DespesaModel despesa, {
    required bool tentarFlush,
  }) async {
    final agora = DateTime.now();

    final despesaLocal = despesa.copyWith(
      dataDespesa: despesa.dataDespesa ?? agora,
      syncStatus: 'pending_create',
    );

    final localId = await _dao.inserir(despesaLocal);

    final despesaComId = despesaLocal.copyWith(idDespesa: localId);

final payload = {
  'localId': localId.toString(),
  'idFornecedor': despesaComId.idFornecedor,
  'idTipoDespesa': despesaComId.idTipoDespesa,
  'descricao': despesaComId.descricao,
  'valorGasto': despesaComId.valorGasto,
};

    await _syncQueueDao.enqueue(
      'despesa',
      'CREATE',
      payload,
    );

    debugPrint(
      '📥 DespesaRepository — despesa criada offline localId=$localId',
    );

    if (tentarFlush && _connectivityService.isOnline) {
      Future.microtask(() => SyncScheduler.instance.flushQueue());
    }

    return despesaComId;
  }

  Future<DespesaModel> editar({
    required int id,
    required DespesaModel despesa,
  }) async {
    _validarDespesa(despesa);

    final atualizadaLocal = despesa.copyWith(idDespesa: id);
    final online = _connectivityService.isOnline;

    if (online) {
      try {
        final atualizada = await _service.editar(
          id: id,
          despesa: atualizadaLocal,
        );

        await _dao.salvarOuAtualizar(atualizada);
        return atualizada;
      } catch (e, s) {
        debugPrint('⚠️ DespesaRepository — API editar falhou: $e');
        debugPrint('$s');

        return _editarOffline(
          id: id,
          despesa: atualizadaLocal,
          tentarFlush: true,
        );
      }
    }

    return _editarOffline(
      id: id,
      despesa: atualizadaLocal,
      tentarFlush: false,
    );
  }

  Future<DespesaModel> _editarOffline({
    required int id,
    required DespesaModel despesa,
    required bool tentarFlush,
  }) async {
    final despesaLocal = despesa.copyWith(
      idDespesa: id,
      syncStatus: 'pending_update',
    );

    await _dao.atualizar(despesaLocal);

final payload = {
  'id': id,
  'localId': id.toString(),
  'idFornecedor': despesaLocal.idFornecedor,
  'idTipoDespesa': despesaLocal.idTipoDespesa,
  'descricao': despesaLocal.descricao,
  'valorGasto': despesaLocal.valorGasto,
};

    await _syncQueueDao.enqueue(
      'despesa',
      'UPDATE',
      payload,
    );

    debugPrint('📝 DespesaRepository — despesa editada offline id=$id');

    if (tentarFlush && _connectivityService.isOnline) {
      Future.microtask(() => SyncScheduler.instance.flushQueue());
    }

    return despesaLocal;
  }

  Future<void> excluir(int id) async {
    final online = _connectivityService.isOnline;

    if (online) {
      try {
        await _service.excluir(id);
        await _dao.excluir(id);
        return;
      } catch (e, s) {
        debugPrint('⚠️ DespesaRepository — API excluir falhou: $e');
        debugPrint('$s');

        await _excluirOffline(id, tentarFlush: true);
        return;
      }
    }

    await _excluirOffline(id, tentarFlush: false);
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
      'despesa',
      'DELETE',
      payload,
    );

    debugPrint('🗑️ DespesaRepository — despesa excluída offline id=$id');

    if (tentarFlush && _connectivityService.isOnline) {
      Future.microtask(() => SyncScheduler.instance.flushQueue());
    }
  }

  void _validarDespesa(DespesaModel despesa) {
  if (despesa.descricao.trim().isEmpty) {
    throw Exception('A descrição da despesa é obrigatória.');
  }

  if (despesa.valorGasto <= 0) {
    throw Exception('O valor gasto deve ser maior que zero.');
  }

  if (despesa.idTipoDespesa == null || despesa.idTipoDespesa! <= 0) {
    throw Exception('O tipo de despesa é obrigatório.');
  }
}

  Future<List<TipoDespesaModel>> listarTiposDespesa() async {
  final online = _connectivityService.isOnline;

  if (online) {
    try {
      final remotos = await _service.listarTiposDespesa();
      await _dao.inserirTiposDespesa(remotos);
      return remotos;
    } catch (_) {
      return _dao.listarTiposDespesa();
    }
  }

  return _dao.listarTiposDespesa();
}

Future<List<DespesaModel>> listarPorPeriodoETipo({
  required DateTime inicio,
  required DateTime fim,
  required int idTipoDespesa,
}) async {
  final online = _connectivityService.isOnline;

  if (online) {
    try {
      final despesas = await _service.listarPorPeriodo(
        inicio: inicio,
        fim: fim,
      );

      await _dao.inserirTodos(despesas);

      return despesas
          .where((d) => d.idTipoDespesa == idTipoDespesa)
          .toList();
    } catch (_) {
      return _dao.listarPorPeriodoETipo(
        inicio: inicio,
        fim: fim,
        idTipoDespesa: idTipoDespesa,
      );
    }
  }

  return _dao.listarPorPeriodoETipo(
    inicio: inicio,
    fim: fim,
    idTipoDespesa: idTipoDespesa,
  );
}


}