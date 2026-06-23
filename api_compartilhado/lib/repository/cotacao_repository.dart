// lib/repository/cotacao_repository.dart

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/cotacao_model.dart';
import '../models/pedido_model.dart';
import '../services/cotacao_service.dart';
import '../core/connectivity/connectivity_service.dart';
import '../core/database/local_database.dart';
import '../core/database/daos/cotacao_dao.dart';
import '../core/database/daos/sync_queue_dao.dart';
import '../core/database/daos/produto_dao.dart';
import '../core/database/daos/servico_dao.dart';

class CotacaoRepository {
  CotacaoRepository({
    required CotacaoService service,
    required CotacaoDao dao,
    required SyncQueueDao syncQueueDao,
    required ConnectivityService connectivity,
    required ProdutoDao produtoDao,
    required ServicoDao servicoDao,
  })  : _service = service,
        _dao = dao,
        _syncQueueDao = syncQueueDao,
        _connectivity = connectivity,
        _produtoDao = produtoDao,
        _servicoDao = servicoDao;

  final CotacaoService _service;
  final CotacaoDao _dao;
  final SyncQueueDao _syncQueueDao;
  final ConnectivityService _connectivity;
  final ProdutoDao _produtoDao;
  final ServicoDao _servicoDao;

  Database get _db => LocalDatabase.instance.db;

  static const _uuid = Uuid();

  // ══════════════════════════════════════════════════════════════════
  // UPSERT COMPLETO (cotação + itens produto + itens serviço)
  // ══════════════════════════════════════════════════════════════════

  Future<void> _upsertCotacaoComItens(CotacaoModel m) async {
    await _dao.upsert(m.toLocalDb());

    await _dao.deleteItensProdutoPorCotacao(m.idCotacao);
    if (m.itensProduto.isNotEmpty) {
      await _dao.upsertAllItensProduto(
        m.itensProduto.map((i) => i.toLocalDb(m.idCotacao)).toList(),
      );
    }

    await _dao.deleteItensServicoPorCotacao(m.idCotacao);
    if (m.itensServico.isNotEmpty) {
      await _dao.upsertAllItensServico(
        m.itensServico.map((i) => i.toLocalDb(m.idCotacao)).toList(),
      );
    }
  }

  Future<void> _recalcularTotalLocal(int idCotacao) async {
    final prodRows = await _dao.getItensProdutoPorCotacao(idCotacao);
    final servRows = await _dao.getItensServicoPorCotacao(idCotacao);

    double total = 0;
    for (final r in prodRows) {
      total += (r['subtotal'] as num?)?.toDouble() ?? 0.0;
    }
    for (final r in servRows) {
      total += (r['subtotal'] as num?)?.toDouble() ?? 0.0;
    }

    await _db.update(
      'cotacao',
      {'total': total, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [idCotacao],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // LEITURA COM ITENS DO CACHE
  // ══════════════════════════════════════════════════════════════════

  Future<CotacaoModel> _cotacaoComItensDoCache(Map<String, dynamic> row) async {
    final cotacao = CotacaoModel.fromLocalDb(row);

    final produtoRows = await _dao.getItensProdutoPorCotacao(cotacao.idCotacao);
    final itensProduto = produtoRows
        .map((r) => CotacaoItemProdutoModel.fromLocalDb(r))
        .toList();

    final servicoRows = await _dao.getItensServicoPorCotacao(cotacao.idCotacao);
    final itensServico = servicoRows
        .map((r) => CotacaoItemServicoModel.fromLocalDb(r))
        .toList();

    return cotacao.copyWith(
      itensProduto: itensProduto,
      itensServico: itensServico,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // LEITURA
  // ══════════════════════════════════════════════════════════════════

  Future<CotacaoModel?> buscarPorId(int idCotacao) async {
    if (_connectivity.isOnline) {
      try {
        final m = await _service.buscarPorId(idCotacao);
        await _upsertCotacaoComItens(m);
        return m;
      } catch (e) {
        debugPrint('⚠️ CotacaoRepository.buscarPorId HTTP falhou — usando cache: $e');
      }
    }
    final row = await _dao.getById(idCotacao);
    return row == null ? null : await _cotacaoComItensDoCache(row);
  }

  Future<List<CotacaoModel>> listarTodas() async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarTodas();
        for (final m in lista) await _upsertCotacaoComItens(m);
        return lista;
      } catch (e) {
        debugPrint('⚠️ CotacaoRepository.listarTodas HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getAllAtivas();
    return Future.wait(rows.map(_cotacaoComItensDoCache));
  }

  Future<List<CotacaoModel>> listarPorStatus(String status) async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarPorStatus(status);
        for (final m in lista) await _upsertCotacaoComItens(m);
        return lista;
      } catch (e) {
        debugPrint('⚠️ CotacaoRepository.listarPorStatus HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getByStatus(status);
    return Future.wait(rows.map(_cotacaoComItensDoCache));
  }

  Future<List<CotacaoModel>> listarPorCliente(int idCliente) async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarPorCliente(idCliente);
        for (final m in lista) await _upsertCotacaoComItens(m);
        return lista;
      } catch (e) {
        debugPrint('⚠️ CotacaoRepository.listarPorCliente HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getByCliente(idCliente);
    return Future.wait(rows.map(_cotacaoComItensDoCache));
  }

  Future<List<CotacaoModel>> listarPorUsuario(int idUsuario) async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarPorUsuario(idUsuario);
        for (final m in lista) await _upsertCotacaoComItens(m);
        return lista;
      } catch (e) {
        debugPrint('⚠️ CotacaoRepository.listarPorUsuario HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getByUsuario(idUsuario);
    return Future.wait(rows.map(_cotacaoComItensDoCache));
  }

Future<List<CotacaoModel>> listarProntas() async {
  if (_connectivity.isOnline) {
    try {
      final lista = await _service.listarProntas();
      for (final m in lista) await _upsertCotacaoComItens(m);
      return lista;
    } catch (e) {
      debugPrint('⚠️ CotacaoRepository.listarProntas HTTP falhou — usando cache: $e');
    }
  }
  final rows = await _dao.getByStatus('PRONTA');
  return Future.wait(rows.map(_cotacaoComItensDoCache));
}

  // ══════════════════════════════════════════════════════════════════
  // CRIAR COTAÇÃO
  // ══════════════════════════════════════════════════════════════════

  Future<CotacaoModel> criarCotacao(CriarCotacaoRequestModel dto) async {
  debugPrint('════════════════════════════════════════════════════');
  debugPrint('🧾 CotacaoRepository.criarCotacao — entrada');
  debugPrint('📡 Online: ${_connectivity.isOnline}');
  debugPrint('👤 idCliente: ${dto.idCliente}');
  debugPrint('👤 nomeClienteSingular: "${dto.nomeClienteSingular}"');
  debugPrint('👤 apelidoClienteSingular: "${dto.apelidoClienteSingular}"');
  debugPrint('📝 observacoes: "${dto.observacoes}"');
  debugPrint('════════════════════════════════════════════════════');

  if (_connectivity.isOnline) {
    try {
      debugPrint('🌐 CotacaoRepository.criarCotacao — enviando para API...');

      final m = await _service.criarCotacao(dto);

      debugPrint('✅ CotacaoRepository.criarCotacao — API respondeu');
      debugPrint('🧾 idCotacao: ${m.idCotacao}');
      debugPrint('👤 retorno.nomeClienteSingular: "${m.nomeClienteSingular}"');
      debugPrint('👤 retorno.apelidoClienteSingular: "${m.apelidoClienteSingular}"');
      debugPrint('👤 retorno.nomeCliente: "${m.nomeCliente}"');

      await _upsertCotacaoComItens(m);

      debugPrint('💾 CotacaoRepository.criarCotacao — cotação salva no SQLite');

      return m;
    } catch (e, s) {
      debugPrint('❌ CotacaoRepository.criarCotacao HTTP falhou: $e');
      debugPrint('$s');
      rethrow;
    }
  }

  // ── Offline ───────────────────────────────────────────────────
  final localId = _uuid.v4();
  final tempId  = -(DateTime.now().millisecondsSinceEpoch);

  debugPrint('📴 CotacaoRepository.criarCotacao — criando offline');
  debugPrint('🆔 localId: $localId');
  debugPrint('🆔 tempId: $tempId');
  debugPrint('👤 offline.nomeClienteSingular: "${dto.nomeClienteSingular}"');
  debugPrint('👤 offline.apelidoClienteSingular: "${dto.apelidoClienteSingular}"');

  final local = CotacaoModel(
    idCotacao:   tempId,
    referencia:  'OFFLINE-${localId.substring(0, 6).toUpperCase()}',
    idCliente:   dto.idCliente,
    nomeClienteSingular: dto.nomeClienteSingular,
    apelidoClienteSingular: dto.apelidoClienteSingular,
    idUsuario:   dto.idUsuario,
    statusCotacao: 'ABERTA',
    total:       0,
    validadeAte: dto.validadeAte,
    observacoes: dto.observacoes,
    createdAt:   DateTime.now(),
    itensProduto: const [],
    itensServico: const [],
  );

  final localDb = {
    ...local.toLocalDb(syncStatus: 'pending'),
    'local_id': localId,
  };

  debugPrint('💾 CotacaoRepository.criarCotacao — localDb: $localDb');

  await _dao.upsert(localDb);

  final payload = {
    'localId': localId,
    'idUsuario': dto.idUsuario,
    'idCliente': dto.idCliente,
    'nomeClienteSingular': dto.nomeClienteSingular,
    'apelidoClienteSingular': dto.apelidoClienteSingular,
    'validadeAte': dto.validadeAte?.toIso8601String().split('T').first,
    'observacoes': dto.observacoes,
  };

  debugPrint('📦 CotacaoRepository.criarCotacao — payload sync_queue: $payload');

  await _syncQueueDao.enqueue('cotacao', 'CREATE', payload);

  debugPrint('✅ CotacaoRepository.criarCotacao — cotação offline enfileirada');

  return local;
}



  // ══════════════════════════════════════════════════════════════════
  // ACTUALIZAR COTAÇÃO
  // ══════════════════════════════════════════════════════════════════

Future<CotacaoModel> atualizarCotacao(
  int idCotacao,
  AtualizarCotacaoRequestModel dto,
) async {
  debugPrint('════════════════════════════════════════════════════');
  debugPrint('🧾 CotacaoRepository.atualizarCotacao — entrada');
  debugPrint('🆔 idCotacao: $idCotacao');
  debugPrint('📡 Online: ${_connectivity.isOnline}');
  debugPrint('👤 idCliente: ${dto.idCliente}');
  debugPrint('👤 nomeClienteSingular: "${dto.nomeClienteSingular}"');
  debugPrint('👤 apelidoClienteSingular: "${dto.apelidoClienteSingular}"');
  debugPrint('📌 statusCotacao: "${dto.statusCotacao}"');
  debugPrint('📝 observacoes: "${dto.observacoes}"');
  debugPrint('════════════════════════════════════════════════════');

  if (_connectivity.isOnline) {
    try {
      debugPrint('🌐 CotacaoRepository.atualizarCotacao — enviando para API...');

      final m = await _service.atualizarCotacao(idCotacao, dto);

      debugPrint('✅ CotacaoRepository.atualizarCotacao — API respondeu');
      debugPrint('🧾 retorno.idCotacao: ${m.idCotacao}');
      debugPrint('👤 retorno.idCliente: ${m.idCliente}');
      debugPrint('👤 retorno.nomeClienteSingular: "${m.nomeClienteSingular}"');
      debugPrint('👤 retorno.apelidoClienteSingular: "${m.apelidoClienteSingular}"');
      debugPrint('👤 retorno.nomeCliente: "${m.nomeCliente}"');

      await _upsertCotacaoComItens(m);

      debugPrint('💾 CotacaoRepository.atualizarCotacao — cotação salva no SQLite');

      return m;
    } catch (e, s) {
      debugPrint('❌ CotacaoRepository.atualizarCotacao HTTP falhou: $e');
      debugPrint('$s');
      rethrow;
    }
  }

  // ── Offline ───────────────────────────────────────────────────
  debugPrint('📴 CotacaoRepository.atualizarCotacao — atualizando offline');

  final values = <String, dynamic>{
    'sync_status': 'pending',
    'updated_at': DateTime.now().toIso8601String(),
  };

  values['id_cliente'] = dto.idCliente;

  if (dto.validadeAte != null) {
    values['validade_ate'] =
        dto.validadeAte!.toIso8601String().split('T').first;
  }

  if (dto.nomeClienteSingular != null) {
    values['nome_cliente_singular'] = dto.nomeClienteSingular;
  }

  if (dto.apelidoClienteSingular != null) {
    values['apelido_cliente_singular'] = dto.apelidoClienteSingular;
  }

  if (dto.observacoes != null) {
    values['observacoes'] = dto.observacoes;
  }

  if (dto.statusCotacao != null) {
    values['status_cotacao'] = dto.statusCotacao;
  }

  debugPrint('💾 CotacaoRepository.atualizarCotacao — values SQLite: $values');

  await _db.update(
    'cotacao',
    values,
    where: 'id = ?',
    whereArgs: [idCotacao],
  );

  final payload = {
    'idCotacao': idCotacao,
    'idCliente': dto.idCliente,
    'nomeClienteSingular': dto.nomeClienteSingular,
    'apelidoClienteSingular': dto.apelidoClienteSingular,
    'validadeAte': dto.validadeAte?.toIso8601String().split('T').first,
    'observacoes': dto.observacoes,
    'statusCotacao': dto.statusCotacao,
  };

  debugPrint('📦 CotacaoRepository.atualizarCotacao — payload sync_queue: $payload');

  await _syncQueueDao.enqueue('cotacao', 'UPDATE', payload);

  final row = await _dao.getById(idCotacao);

  debugPrint('🔎 CotacaoRepository.atualizarCotacao — row após update: $row');

  return row != null
      ? await _cotacaoComItensDoCache(row)
      : _cotacaoVazia(idCotacao);
}

  // ══════════════════════════════════════════════════════════════════
  // EXCLUIR (soft delete)
  // ══════════════════════════════════════════════════════════════════

  Future<void> excluirCotacao(int idCotacao) async {
    if (_connectivity.isOnline) {
      await _service.excluirCotacao(idCotacao);
      await _dao.marcarDeletada(idCotacao);
      return;
    }

    // ── Offline ───────────────────────────────────────────────────
    await _dao.marcarDeletada(idCotacao, syncStatus: 'pending');

    await _syncQueueDao.enqueue('cotacao', 'DELETE', {
      'idCotacao': idCotacao,
    });
  }

  // ══════════════════════════════════════════════════════════════════
  // ITENS DE PRODUTO
  // ══════════════════════════════════════════════════════════════════

  Future<CotacaoModel> adicionarProduto(
    int idCotacao,
    AdicionarProdutoCotacaoRequestModel dto,
  ) async {
    if (_connectivity.isOnline) {
      final m = await _service.adicionarProduto(idCotacao, dto);
      await _upsertCotacaoComItens(m);
      return m;
    }

    // ── Offline ───────────────────────────────────────────────────
    final prodRow = await _produtoDao.getById(dto.idProduto);
    final preco = dto.precoUnitario ??
        (prodRow != null
            ? ((prodRow['preco_promocional'] as num?)?.toDouble() ??
                (prodRow['preco'] as num?)?.toDouble() ?? 0.0)
            : 0.0);
    final nomeProduto = prodRow?['nome_produto'] as String?;

    // Se já existir item do mesmo produto, incrementa em vez de duplicar
    final existente = await _dao.getItemProdutoPorProduto(idCotacao, dto.idProduto);
    if (existente != null) {
      final novaQtd = ((existente['quantidade'] as int?) ?? 0) + dto.quantidade;
      final novoSubtotal = preco * novaQtd;
      await _dao.upsertItemProduto({
        ...existente,
        'quantidade': novaQtd,
        'preco_unitario': preco,
        'subtotal': novoSubtotal,
      });
    } else {
      final subtotal = preco * dto.quantidade;
      await _dao.upsertItemProduto({
        'id':             -(DateTime.now().microsecondsSinceEpoch),
        'id_cotacao':     idCotacao,
        'id_produto':     dto.idProduto,
        'nome_produto':   nomeProduto,
        'preco_unitario': preco,
        'quantidade':     dto.quantidade,
        'subtotal':       subtotal,
        'observacoes':    dto.observacoes,
      });
    }

    await _recalcularTotalLocal(idCotacao);
    await _marcarPendente(idCotacao);

    await _syncQueueDao.enqueue('cotacao', 'ADD_ITEM_PRODUTO', {
      'idCotacao':     idCotacao,
      'idProduto':     dto.idProduto,
      'quantidade':    dto.quantidade,
      'precoUnitario': dto.precoUnitario,
      'observacoes':   dto.observacoes,
    });

    final row = await _dao.getById(idCotacao);
    return row != null ? await _cotacaoComItensDoCache(row) : _cotacaoVazia(idCotacao);
  }

  Future<CotacaoModel> atualizarItemProduto(
    int idCotacao,
    int idItem,
    AtualizarItemCotacaoRequestModel dto,
  ) async {
    if (_connectivity.isOnline) {
      final m = await _service.atualizarItemProduto(idCotacao, idItem, dto);
      await _upsertCotacaoComItens(m);
      return m;
    }

    // ── Offline ───────────────────────────────────────────────────
    final item = await _dao.getItemProdutoPorId(idItem, idCotacao);
    if (item != null) {
      final preco = dto.precoUnitario ?? (item['preco_unitario'] as num?)?.toDouble() ?? 0.0;
      final subtotal = preco * dto.quantidade;
      await _dao.upsertItemProduto({
        ...item,
        'quantidade':     dto.quantidade,
        'preco_unitario': preco,
        'subtotal':       subtotal,
        'observacoes':    dto.observacoes ?? item['observacoes'],
      });
    }

    await _recalcularTotalLocal(idCotacao);
    await _marcarPendente(idCotacao);

    await _syncQueueDao.enqueue('cotacao', 'EDIT_ITEM_PRODUTO', {
      'idCotacao':     idCotacao,
      'idItem':        idItem,
      'quantidade':    dto.quantidade,
      'precoUnitario': dto.precoUnitario,
      'observacoes':   dto.observacoes,
    });

    final row = await _dao.getById(idCotacao);
    return row != null ? await _cotacaoComItensDoCache(row) : _cotacaoVazia(idCotacao);
  }

  Future<CotacaoModel> removerItemProduto(int idCotacao, int idItem) async {
    if (_connectivity.isOnline) {
      final m = await _service.removerItemProduto(idCotacao, idItem);
      await _upsertCotacaoComItens(m);
      return m;
    }

    // ── Offline ───────────────────────────────────────────────────
    await _dao.deleteItemProduto(idItem);
    await _recalcularTotalLocal(idCotacao);
    await _marcarPendente(idCotacao);

    await _syncQueueDao.enqueue('cotacao', 'REMOVE_ITEM_PRODUTO', {
      'idCotacao': idCotacao,
      'idItem':    idItem,
    });

    final row = await _dao.getById(idCotacao);
    return row != null ? await _cotacaoComItensDoCache(row) : _cotacaoVazia(idCotacao);
  }

  // ══════════════════════════════════════════════════════════════════
  // ITENS DE SERVIÇO
  // ══════════════════════════════════════════════════════════════════

  Future<CotacaoModel> adicionarServico(
    int idCotacao,
    AdicionarServicoCotacaoRequestModel dto,
  ) async {
    if (_connectivity.isOnline) {
      final m = await _service.adicionarServico(idCotacao, dto);
      await _upsertCotacaoComItens(m);
      return m;
    }

    // ── Offline ───────────────────────────────────────────────────
    final servRow = await _servicoDao.getById(dto.idServico);
    final preco = dto.precoUnitario ??
        (servRow != null ? (servRow['preco_unitario'] as num?)?.toDouble() ?? 0.0 : 0.0);
    final nomeServico = servRow?['nome_servico'] as String?;

    final existente = await _dao.getItemServicoPorServico(idCotacao, dto.idServico);
    if (existente != null) {
      final novaQtd = ((existente['quantidade'] as int?) ?? 0) + dto.quantidade;
      final novoSubtotal = preco * novaQtd;
      await _dao.upsertItemServico({
        ...existente,
        'quantidade': novaQtd,
        'preco_unitario': preco,
        'subtotal': novoSubtotal,
      });
    } else {
      final subtotal = preco * dto.quantidade;
      await _dao.upsertItemServico({
        'id':             -(DateTime.now().microsecondsSinceEpoch),
        'id_cotacao':     idCotacao,
        'id_servico':     dto.idServico,
        'nome_servico':   nomeServico,
        'preco_unitario': preco,
        'quantidade':     dto.quantidade,
        'subtotal':       subtotal,
        'observacoes':    dto.observacoes,
      });
    }

    await _recalcularTotalLocal(idCotacao);
    await _marcarPendente(idCotacao);

    await _syncQueueDao.enqueue('cotacao', 'ADD_ITEM_SERVICO', {
      'idCotacao':     idCotacao,
      'idServico':     dto.idServico,
      'quantidade':    dto.quantidade,
      'precoUnitario': dto.precoUnitario,
      'observacoes':   dto.observacoes,
    });

    final row = await _dao.getById(idCotacao);
    return row != null ? await _cotacaoComItensDoCache(row) : _cotacaoVazia(idCotacao);
  }

  Future<CotacaoModel> atualizarItemServico(
    int idCotacao,
    int idItem,
    AtualizarItemCotacaoRequestModel dto,
  ) async {
    if (_connectivity.isOnline) {
      final m = await _service.atualizarItemServico(idCotacao, idItem, dto);
      await _upsertCotacaoComItens(m);
      return m;
    }

    // ── Offline ───────────────────────────────────────────────────
    final item = await _dao.getItemServicoPorId(idItem, idCotacao);
    if (item != null) {
      final preco = dto.precoUnitario ?? (item['preco_unitario'] as num?)?.toDouble() ?? 0.0;
      final subtotal = preco * dto.quantidade;
      await _dao.upsertItemServico({
        ...item,
        'quantidade':     dto.quantidade,
        'preco_unitario': preco,
        'subtotal':       subtotal,
        'observacoes':    dto.observacoes ?? item['observacoes'],
      });
    }

    await _recalcularTotalLocal(idCotacao);
    await _marcarPendente(idCotacao);

    await _syncQueueDao.enqueue('cotacao', 'EDIT_ITEM_SERVICO', {
      'idCotacao':     idCotacao,
      'idItem':        idItem,
      'quantidade':    dto.quantidade,
      'precoUnitario': dto.precoUnitario,
      'observacoes':   dto.observacoes,
    });

    final row = await _dao.getById(idCotacao);
    return row != null ? await _cotacaoComItensDoCache(row) : _cotacaoVazia(idCotacao);
  }

  Future<CotacaoModel> removerItemServico(int idCotacao, int idItem) async {
    if (_connectivity.isOnline) {
      final m = await _service.removerItemServico(idCotacao, idItem);
      await _upsertCotacaoComItens(m);
      return m;
    }

    // ── Offline ───────────────────────────────────────────────────
    await _dao.deleteItemServico(idItem);
    await _recalcularTotalLocal(idCotacao);
    await _marcarPendente(idCotacao);

    await _syncQueueDao.enqueue('cotacao', 'REMOVE_ITEM_SERVICO', {
      'idCotacao': idCotacao,
      'idItem':    idItem,
    });

    final row = await _dao.getById(idCotacao);
    return row != null ? await _cotacaoComItensDoCache(row) : _cotacaoVazia(idCotacao);
  }

  // ══════════════════════════════════════════════════════════════════
  // CONVERSÃO — requer ligação (cria pedido no backend)
  // ══════════════════════════════════════════════════════════════════

Future<PedidoModel> converterEmPedido(
  int idCotacao,
  ConverterCotacaoEmPedidoRequestModel dto,
) async {
  if (_connectivity.isOffline) {
    throw Exception(
      'Sem ligação — a conversão em pedido requer internet.',
    );
  }

  // Busca a cotação local antes da conversão para preservar cliente singular
  final rowCotacao = await _dao.getById(idCotacao);
  final cotacaoLocal = rowCotacao != null
      ? await _cotacaoComItensDoCache(rowCotacao)
      : null;

final dtoCorrigido = ConverterCotacaoEmPedidoRequestModel(
  idTipoPagamento: dto.idTipoPagamento,

  idCliente: cotacaoLocal?.idCliente ?? dto.idCliente,

  nomeClienteSingular:
      dto.nomeClienteSingular ?? cotacaoLocal?.nomeClienteSingular,

  apelidoClienteSingular:
      dto.apelidoClienteSingular ?? cotacaoLocal?.apelidoClienteSingular,

  observacoes: dto.observacoes,
);

  final pedido = await _service.converterEmPedido(idCotacao, dtoCorrigido);

  // Actualiza o estado local da cotação para reflectir a conversão
  await _db.update(
    'cotacao',
    {
      'status_cotacao': 'CONVERTIDA',
      'id_pedido_convertido': pedido.idPedido,
      'referencia_pedido_convertido': pedido.referencia,
      'sync_status': 'synced',
      'updated_at': DateTime.now().toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [idCotacao],
  );

  return pedido;
}

  // ══════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════

  Future<void> _marcarPendente(int idCotacao) async {
    await _db.update(
      'cotacao',
      {'sync_status': 'pending', 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [idCotacao],
    );
  }

  CotacaoModel _cotacaoVazia(int idCotacao) => CotacaoModel(
        idCotacao:  idCotacao,
        referencia: '',
        idUsuario:  0,
        statusCotacao: 'ABERTA',
        total: 0,
      );
}
