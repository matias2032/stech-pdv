// lib/repository/pedido_repository.dart

import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import '../core/database/daos/pedido_dao.dart';
import '../core/connectivity/connectivity_service.dart';
import '../services/pedido_service.dart';
import 'package:uuid/uuid.dart';
import '../core/database/daos/produto_dao.dart';
import '../core/database/daos/sync_queue_dao.dart';
import '../core/database/local_database.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database/daos/servico_dao.dart';

class PedidoRepository {
  PedidoRepository({
    required PedidoService service,
    required PedidoDao dao,
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

  final PedidoService _service;
  final PedidoDao _dao;
  final SyncQueueDao _syncQueueDao;
  final ConnectivityService _connectivity;
  final ProdutoDao _produtoDao;
   final ServicoDao _servicoDao;   
  Database get _db => LocalDatabase.instance.db;

  static const _uuid = Uuid();

  // ══════════════════════════════════════════════════════════════════
  // UPSERT COMPLETO (pedido + itens produto + itens serviço)
  // ══════════════════════════════════════════════════════════════════

  Future<void> _upsertPedidoComItens(PedidoModel m) async {
    await _dao.upsert(m.toLocalDb());

    // Itens de produto
    await _dao.deleteItensByPedido(m.idPedido);
    final itensProduto = m.itensProduto.map((i) => {
          'id':             i.idItemPedido,
          'id_pedido':      m.idPedido,
          'id_produto':     i.idProduto,
          'preco_unitario': i.precoUnitario,
          'quantidade':     i.quantidade,
          'subtotal':       i.subtotal,
        }).toList();
    if (itensProduto.isNotEmpty) await _dao.upsertAllItens(itensProduto);

    // Itens de serviço
    await _dao.deleteItensServicoPorPedido(m.idPedido);
    final itensServico = m.itensServico.map((i) => {
          'id':             i.idItemServico,
          'id_pedido':      m.idPedido,
          'id_servico':     i.idServico,
          'preco_unitario': i.precoUnitario,
          'quantidade':     i.quantidade,
          'subtotal':       i.subtotal,
          'observacoes':    i.observacoes,
        }).toList();
    if (itensServico.isNotEmpty) await _dao.upsertAllItensServico(itensServico);
  }

  Future<void> _recalcularTotalLocal(int idPedido) async {
    final prodRows = await _dao.getItensByPedido(idPedido);
    final servRows = await _dao.getItensServicoPorPedido(idPedido);

    double total = 0;
    for (final r in prodRows) {
      total += (r['subtotal'] as num?)?.toDouble() ?? 0.0;
    }
    for (final r in servRows) {
      total += (r['subtotal'] as num?)?.toDouble() ?? 0.0;
    }

    await _db.update(
      'pedido',
      {'total': total, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [idPedido],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // LEITURA COM ITENS DO CACHE
  // ══════════════════════════════════════════════════════════════════

  Future<PedidoModel> _pedidoComItensDoCache(Map<String, dynamic> row) async {
    final pedido = PedidoModel.fromLocalDb(row);

    // Produtos
    final produtoRows = await _dao.getItensByPedido(pedido.idPedido);
    final itensProduto = produtoRows.map((r) => ItemPedidoModel(
          idItemPedido:  (r['id'] as int?) ?? 0,
          idProduto:     (r['id_produto'] as int?) ?? 0,
          nomeProduto:   'Produto #${r['id_produto']}',
          quantidade:    (r['quantidade'] as int?) ?? 0,
          precoUnitario: (r['preco_unitario'] as num?)?.toDouble() ?? 0.0,
          subtotal:      (r['subtotal'] as num?)?.toDouble() ?? 0.0,
        )).toList();

    // Serviços
    final servicoRows = await _dao.getItensServicoPorPedido(pedido.idPedido);
    final itensServico = servicoRows.map((r) => ItemPedidoServicoModel(
          idItemServico: (r['id'] as int?) ?? 0,
          idServico:     (r['id_servico'] as int?) ?? 0,
          nomeServico:   'Serviço #${r['id_servico']}',
          quantidade:    (r['quantidade'] as int?) ?? 0,
          precoUnitario: (r['preco_unitario'] as num?)?.toDouble() ?? 0.0,
          subtotal:      (r['subtotal'] as num?)?.toDouble() ?? 0.0,
          observacoes:   r['observacoes'] as String?,
        )).toList();

    return pedido.copyWith(
      itensProduto: itensProduto,
      itensServico: itensServico,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // LEITURA
  // ══════════════════════════════════════════════════════════════════

  Future<PedidoModel?> buscarPorId(int idPedido) async {
    if (_connectivity.isOnline) {
      try {
        final m = await _service.buscarPorId(idPedido);
        await _upsertPedidoComItens(m);
        return m;
      } catch (e) {
        debugPrint('⚠️ PedidoRepository.buscarPorId HTTP falhou — usando cache: $e');
      }
    }
    final row = await _dao.getById(idPedido);
    return row == null ? null : await _pedidoComItensDoCache(row);
  }

  Future<List<PedidoModel>> listarPorUsuario(int idUsuario) async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarPorUsuario(idUsuario);
        for (final m in lista) await _upsertPedidoComItens(m);
        return lista;
      } catch (e) {
        debugPrint('⚠️ PedidoRepository.listarPorUsuario HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getByUsuario(idUsuario);
    return Future.wait(rows.map(_pedidoComItensDoCache));
  }

  Future<List<PedidoModel>> listarPorStatus(String status) async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarPorStatus(status);
        for (final m in lista) await _upsertPedidoComItens(m);
        return lista;
      } catch (e) {
        debugPrint('⚠️ PedidoRepository.listarPorStatus HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getByStatus(status);
    return Future.wait(rows.map(_pedidoComItensDoCache));
  }

  Future<List<PedidoModel>> listarPorUsuarioEStatus(
    int idUsuario,
    String status,
  ) async {
    if (_connectivity.isOnline) {
      try {
        final lista = await _service.listarPorUsuarioEStatus(idUsuario, status);
        for (final m in lista) await _upsertPedidoComItens(m);
        return lista;
      } catch (e) {
        debugPrint('⚠️ PedidoRepository.listarPorUsuarioEStatus HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _dao.getByUsuarioEStatus(idUsuario, status);
    return Future.wait(rows.map(_pedidoComItensDoCache));
  }

  Future<List<TipoPagamentoResponseDTO>> listarTiposPagamento() async {
    if (_connectivity.isOnline) {
      try {
        final tipos = await _service.listarTiposPagamento();
        final batch = _db.batch();
        for (final t in tipos) {
          batch.insert(
            'tipo_pagamento',
            {'id': t.idTipoPagamento, 'tipo_pagamento': t.tipoPagamento},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        return tipos;
      } catch (e) {
        debugPrint('⚠️ listarTiposPagamento HTTP falhou — usando cache: $e');
      }
    }
    final rows = await _db.rawQuery('SELECT * FROM tipo_pagamento');
    if (rows.isEmpty) {
      throw Exception(
        'Tipos de pagamento não disponíveis offline. '
        'Ligue-se uma vez para sincronizar.',
      );
    }
    return rows
        .map((r) => TipoPagamentoResponseDTO(
              idTipoPagamento: r['id'] as int,
              tipoPagamento:   r['tipo_pagamento'] as String,
            ))
        .toList();
  }

  Future<Map<String, dynamic>> relatorioPedidosUsuario(
    int idUsuario, {
    required DateTime dataInicio,
  }) async {
    if (_connectivity.isOffline) {
      throw Exception('Sem ligação — relatório requer internet.');
    }
    return _service.relatorioPedidosUsuario(idUsuario, dataInicio: dataInicio);
  }

  Future<Map<String, dynamic>> dashboardUsuario(
    int idUsuario, {
    required DateTime dataInicio,
  }) async {
    if (_connectivity.isOffline) {
      throw Exception('Sem ligação — dashboard requer internet.');
    }
    return _service.dashboardUsuario(idUsuario, dataInicio: dataInicio);
  }

  Future<int> contarPedidosAbertos() async {
    if (_connectivity.isOffline) {
      final rows = await _dao.getByStatus('aberto');
      return rows.length;
    }
    return _service.contarPedidosAbertos();
  }

  // ══════════════════════════════════════════════════════════════════
  // CRIAR PEDIDO
  // ══════════════════════════════════════════════════════════════════

  Future<PedidoModel> criarPedido(PedidoRequestModel dto) async {
    if (_connectivity.isOnline) {
      try {
        final m = await _service.criarPedido(dto);
        await _upsertPedidoComItens(m);
        return m;
      } catch (e) {
        debugPrint('⚠️ PedidoRepository.criarPedido HTTP falhou: $e');
        rethrow;
      }
    }

    // ── Offline ───────────────────────────────────────────────────
    final localId = _uuid.v4();
    final tempId  = -(DateTime.now().millisecondsSinceEpoch);

    final local = PedidoModel(
      idPedido:        tempId,
      referencia:      'OFFLINE-${localId.substring(0, 6).toUpperCase()}',
      idUsuario:       dto.idUsuario,
      idTipoPagamento: dto.idTipoPagamento,
      statusPedido:    'aberto',        // ← CORRIGIDO: era 'rascunho'
      total:           0,
      valorPago:       0,
      pontoReferencia: dto.pontoReferencia,
      observacoes:     dto.observacoes,
      dataPedido:      DateTime.now(),
      itensProduto:    const [],
      itensServico:    const [],
    );

    await _dao.upsert({
      ...local.toLocalDb(),
      'local_id':    localId,
      'sync_status': 'pending',
    });

    // Itens de produto iniciais
    for (final item in dto.itensProduto) {
      final prodRow = await _produtoDao.getById(item.idProduto);
      final preco = prodRow != null
          ? ((prodRow['preco_promocional'] as num?)?.toDouble() ??
             (prodRow['preco'] as num?)?.toDouble() ?? 0.0)
          : 0.0;
      final subtotal = preco * item.quantidade;

      await _dao.upsertItem({
        'id':             -(DateTime.now().microsecondsSinceEpoch + item.idProduto),
        'id_pedido':      tempId,
        'id_produto':     item.idProduto,
        'preco_unitario': preco,
        'quantidade':     item.quantidade,
        'subtotal':       subtotal,
      });
      await _produtoDao.decrementarEstoque(item.idProduto, item.quantidade);
    }


    // Itens de serviço iniciais
   for (final item in dto.itensServico) {
      final servRow = await _servicoDao.getById(item.idServico);
      final preco = servRow != null
          ? (servRow['preco_unitario'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      final subtotal = preco * item.quantidade;

      await _dao.upsertItemServico({
        'id':             -(DateTime.now().microsecondsSinceEpoch + item.idServico),
        'id_pedido':      tempId,
        'id_servico':     item.idServico,
        'preco_unitario': preco,
        'quantidade':     item.quantidade,
        'subtotal':       subtotal,
        'observacoes':    item.observacoes,
      });
    }

    // Recalcula e persiste o total no registo do pedido
    await _recalcularTotalLocal(tempId);

    await _syncQueueDao.enqueue('pedido', 'CREATE', {
      'localId':         localId,
      'idUsuario':       dto.idUsuario,
      'idTipoPagamento': dto.idTipoPagamento,
      'pontoReferencia': dto.pontoReferencia,
      'observacoes':     dto.observacoes,
      'itensProduto':    dto.itensProduto.map((i) => i.toJson()).toList(),
      'itensServico':    dto.itensServico.map((i) => i.toJson()).toList(),
    });

    return local;
  }

  // ══════════════════════════════════════════════════════════════════
  // ADICIONAR ITEM DE PRODUTO
  // ══════════════════════════════════════════════════════════════════

  Future<PedidoModel> adicionarItemProduto(
    int idPedido,
    ItemPedidoRequestDTO dto,
  ) async {
    if (_connectivity.isOnline) {
      final m = await _service.adicionarItemProduto(idPedido, dto);
      await _upsertPedidoComItens(m);
      return m;
    }

    // ── Offline ───────────────────────────────────────────────────
    final prodRow = await _produtoDao.getById(dto.idProduto);
    final preco = prodRow != null
        ? ((prodRow['preco_promocional'] as num?)?.toDouble() ??
           (prodRow['preco'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final subtotal = preco * dto.quantidade;

    await _dao.upsertItem({
      'id':             -(DateTime.now().millisecondsSinceEpoch),
      'id_pedido':      idPedido,
      'id_produto':     dto.idProduto,
      'preco_unitario': preco,
      'quantidade':     dto.quantidade,
      'subtotal':       subtotal,
    });

    await _produtoDao.decrementarEstoque(dto.idProduto, dto.quantidade);
    await _recalcularTotalLocal(idPedido);   // ← NOVO

    await _syncQueueDao.enqueue('pedido', 'ADD_ITEM_PRODUTO', {
      'idPedido':      idPedido.isNegative ? null        : idPedido,
      'idPedidoLocal': idPedido.isNegative ? '$idPedido' : null,
      'idProduto':     dto.idProduto,
      'quantidade':    dto.quantidade,
    });

    final row = await _dao.getById(idPedido);
    return row != null
        ? await _pedidoComItensDoCache(row)   // ← CORRIGIDO
        : _pedidoVazio(idPedido);
  }

  

  // ══════════════════════════════════════════════════════════════════
  // ADICIONAR ITEM DE SERVIÇO
  // ══════════════════════════════════════════════════════════════════

  Future<PedidoModel> adicionarItemServico(
    int idPedido,
    ItemServicoRequestDTO dto,
  ) async {
    if (_connectivity.isOnline) {
      final m = await _service.adicionarItemServico(idPedido, dto);
      await _upsertPedidoComItens(m);
      return m;
    }

    // ── Offline ───────────────────────────────────────────────────
    final servRow = await _servicoDao.getById(dto.idServico);
    final preco = servRow != null
        ? (servRow['preco_unitario'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final subtotal = preco * dto.quantidade;

    await _dao.upsertItemServico({
      'id':             -(DateTime.now().millisecondsSinceEpoch),
      'id_pedido':      idPedido,
      'id_servico':     dto.idServico,
      'preco_unitario': preco,
      'quantidade':     dto.quantidade,
      'subtotal':       subtotal,
      'observacoes':    dto.observacoes,
    });

    await _recalcularTotalLocal(idPedido);   // ← NOVO

    await _syncQueueDao.enqueue('pedido', 'ADD_ITEM_SERVICO', {
      'idPedido':      idPedido.isNegative ? null        : idPedido,
      'idPedidoLocal': idPedido.isNegative ? '$idPedido' : null,
      'idServico':     dto.idServico,
      'quantidade':    dto.quantidade,
      'observacoes':   dto.observacoes,
    });

    final row = await _dao.getById(idPedido);
    return row != null
        ? await _pedidoComItensDoCache(row)   // ← CORRIGIDO
        : _pedidoVazio(idPedido);
  }

  // ══════════════════════════════════════════════════════════════════
  // EDITAR / ELIMINAR ITENS
  // ══════════════════════════════════════════════════════════════════

  Future<PedidoModel> editarQuantidadeItemProduto(
    int idPedido,
    int idItemPedido,
    EditarItemRequestDTO dto,
  ) async {
    if (_connectivity.isOnline) {
      final m = await _service.editarQuantidadeItemProduto(idPedido, idItemPedido, dto);
      await _upsertPedidoComItens(m);
      return m;
    }
    await _syncQueueDao.enqueue('pedido', 'EDIT_ITEM_PRODUTO', {
      'idPedido':       idPedido,
      'idItemPedido':   idItemPedido,
      'novaQuantidade': dto.novaQuantidade,
    });
    final row = await _dao.getById(idPedido);
    return row != null ? await _pedidoComItensDoCache(row) : _pedidoVazio(idPedido);
  }

  Future<PedidoModel> editarQuantidadeItemServico(
    int idPedido,
    int idItemServico,
    EditarItemRequestDTO dto,
  ) async {
    if (_connectivity.isOnline) {
      final m = await _service.editarQuantidadeItemServico(idPedido, idItemServico, dto);
      await _upsertPedidoComItens(m);
      return m;
    }
    await _syncQueueDao.enqueue('pedido', 'EDIT_ITEM_SERVICO', {
      'idPedido':       idPedido,
      'idItemServico':  idItemServico,
      'novaQuantidade': dto.novaQuantidade,
    });
    final row = await _dao.getById(idPedido);
    return row != null ? await _pedidoComItensDoCache(row) : _pedidoVazio(idPedido);
  }

  Future<PedidoModel> eliminarItemProduto(int idPedido, int idItemPedido) async {
    if (_connectivity.isOnline) {
      final m = await _service.eliminarItemProduto(idPedido, idItemPedido);
      await _upsertPedidoComItens(m);
      return m;
    }
    // ← CORRIGIDO: apaga pelo idItemPedido, não pelo idPedido
    await _db.delete('item_pedido', where: 'id = ?', whereArgs: [idItemPedido]);
    await _syncQueueDao.enqueue('pedido', 'REMOVE_ITEM_PRODUTO', {
      'idPedido':     idPedido,
      'idItemPedido': idItemPedido,
    });
    final row = await _dao.getById(idPedido);
    return row != null ? await _pedidoComItensDoCache(row) : _pedidoVazio(idPedido);
  }

  Future<PedidoModel> eliminarItemServico(int idPedido, int idItemServico) async {
    if (_connectivity.isOnline) {
      final m = await _service.eliminarItemServico(idPedido, idItemServico);
      await _upsertPedidoComItens(m);
      return m;
    }
    await _db.delete(
      'item_pedido_servico', where: 'id = ?', whereArgs: [idItemServico],
    );
    await _syncQueueDao.enqueue('pedido', 'REMOVE_ITEM_SERVICO', {
      'idPedido':      idPedido,
      'idItemServico': idItemServico,
    });
    final row = await _dao.getById(idPedido);
    return row != null ? await _pedidoComItensDoCache(row) : _pedidoVazio(idPedido);
  }

  // ══════════════════════════════════════════════════════════════════
  // FINALIZAR / CANCELAR
  // ══════════════════════════════════════════════════════════════════

Future<PedidoModel> finalizarPedido(
  int idPedido,
  FinalizarPedidoRequestDTO dto,
) async {
  if (_connectivity.isOnline) {
    final m = await _service.finalizarPedido(idPedido, dto);
    await _upsertPedidoComItens(m);
    return m;
  }

  // ── Offline ───────────────────────────────────────────────────────
  // Actualiza o estado local imediatamente (optimistic)
  await _db.update(
    'pedido',
    {
      'status_pedido': 'finalizado',
      'id_tipo_pagamento': dto.idTipoPagamento,
      'valor_pago': dto.valorPago,
      'sync_status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [idPedido],
  );

  // Enfileira para sync posterior
  await _syncQueueDao.enqueue('pedido', 'FINALIZAR', {
    // Se idPedido < 0 ainda não foi sincronizado — usa local ref
    'idPedido':      idPedido.isNegative ? null        : idPedido,
    'idPedidoLocal': idPedido.isNegative ? '$idPedido' : null,
    'idTipoPagamento':        dto.idTipoPagamento,
    'valorPago':              dto.valorPago,
    'observacoes':            dto.observacoes,
    'idCliente':              dto.idCliente,
    'nomeClienteSingular':    dto.nomeClienteSingular,
    'apelidoClienteSingular': dto.apelidoClienteSingular,
  });

  // Retorna o modelo local actualizado
  final row = await _dao.getById(idPedido);
  return row != null
      ? await _pedidoComItensDoCache(row)
      : _pedidoVazio(idPedido);
}

  Future<void> cancelarPedido(
    int idPedido,
    CancelamentoPedidoRequestDTO dto,
  ) async {
    if (_connectivity.isOnline) {
      await _service.cancelarPedido(idPedido, dto);
      await _dao.delete(idPedido);
      return;
    }

    // Offline — restaura estoque dos produtos
    final itens = await _dao.getItensByPedido(idPedido);
    for (final item in itens) {
      final idProduto  = item['id_produto'] as int?;
      final quantidade = item['quantidade'] as int?;
      if (idProduto != null && quantidade != null) {
        await _produtoDao.incrementarEstoque(idProduto, quantidade);
      }
    }

    await _dao.upsert({
      'id':            idPedido,
      'status_pedido': 'cancelado',
      'sync_status':   'pending',
      'updated_at':    DateTime.now().toIso8601String(),
    });

    await _syncQueueDao.enqueue('pedido', 'CANCEL', {
      'idPedido':          idPedido,
      'idUsuarioCancelou': dto.idUsuarioCancelou,
      'motivo':            dto.motivo,
    });
  }

  // ══════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════

  void _requireOnline(String operacao) {
    if (_connectivity.isOffline) {
      throw Exception('Sem ligação — "$operacao" requer internet.');
    }
  }

  PedidoModel _pedidoVazio(int idPedido) => PedidoModel(
        idPedido:        idPedido,
        referencia:      '',
        idUsuario:       0,
        idTipoPagamento: 0,
        statusPedido:    'aberto',
        total:           0,
        valorPago:       0,
        dataPedido:      DateTime.now(),
      );

Future<void> _enqueuePedidoOperation({
  required String operacao,
  required int idPedido,
  required Map<String, dynamic> payload,
}) async {
  final fullPayload = {
    ...payload,

    // Se o pedido ainda for temporário/offline, o SyncScheduler deve resolver depois.
    'idPedido': idPedido.isNegative ? null : idPedido,
    'idPedidoLocal': idPedido.isNegative ? '$idPedido' : null,
  };

  await _syncQueueDao.enqueue(
    'pedido',
    operacao,
    fullPayload,
  );
}
Future<PedidoModel> declararCredito(
  int idPedido,
  DeclararCreditoRequestModel dto,
) async {
  final online = _connectivity.isOnline;

  if (online) {
    try {
      final pedido = await _service.declararCredito(idPedido, dto);
      await _upsertPedidoComItens(pedido);
      return pedido;
    } catch (e) {
      debugPrint('⚠️ PedidoRepository.declararCredito online falhou; enfileirando: $e');
    }
  }

  final payload = dto.toJson();

  await _enqueuePedidoOperation(
    operacao: 'DECLARAR_CREDITO',
    idPedido: idPedido,
    payload: payload,
  );

  await _db.update(
    'pedido',
    {
      'tipo_venda': 'CREDITO',
      'modalidade_credito': dto.modalidadeCredito,
      'status_pedido': 'em dívida',
      'status_pagamento': 'PENDENTE',
      'data_abertura_credito': DateTime.now().toIso8601String(),
      'data_vencimento_credito':
          dto.dataVencimento?.toIso8601String().split('T').first,
      'observacoes_credito': dto.observacoesCredito,
      'sync_status': 'pending_update',
      'updated_at': DateTime.now().toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [idPedido],
  );

  final row = await _dao.getById(idPedido);
  if (row == null) {
    throw Exception('Pedido $idPedido não encontrado no cache local.');
  }

  return _pedidoComItensDoCache(row);
}

Future<List<ParcelaCreditoModel>> criarParcelas(
  int idPedido,
  CriarParcelasRequestModel dto,
) async {
  final online = _connectivity.isOnline;

  if (online) {
    try {
      final parcelas = await _service.criarParcelas(idPedido, dto);
      // O cache local das parcelas será feito no PedidoDao no próximo passo.
      return parcelas;
    } catch (e) {
      debugPrint('⚠️ PedidoRepository.criarParcelas online falhou; enfileirando: $e');
    }
  }

  await _enqueuePedidoOperation(
    operacao: 'CRIAR_PARCELAS',
    idPedido: idPedido,
    payload: dto.toJson(),
  );

  final agora = DateTime.now();

  final parcelasLocais = dto.parcelas
      .map((p) => ParcelaCreditoModel(
            idParcela: -agora.microsecondsSinceEpoch - p.numeroParcela,
            idPedido: idPedido,
            numeroParcela: p.numeroParcela,
            valorParcela: p.valorParcela,
            valorPago: 0.0,
            saldoParcela: p.valorParcela,
            dataVencimento: p.dataVencimento,
            dataPagamento: null,
            statusParcela: 'PENDENTE',
            observacoes: null,
          ))
      .toList();

  // Persistência local real das parcelas fica para o PedidoDao.
  return parcelasLocais;
}

Future<PagamentoCreditoModel> registarPagamentoCredito(
  int idPedido,
  RegistarPagamentoCreditoRequestModel dto,
) async {
  final online = _connectivity.isOnline;

  if (online) {
    try {
      final pagamento = await _service.registarPagamentoCredito(idPedido, dto);

      final atualizado = await _service.buscarPorId(idPedido);
      await _upsertPedidoComItens(atualizado);

      return pagamento;
    } catch (e) {
      debugPrint(
        '⚠️ PedidoRepository.registarPagamentoCredito online falhou; enfileirando: $e',
      );
    }
  }

  final row = await _dao.getById(idPedido);
  if (row == null) {
    throw Exception('Pedido $idPedido não encontrado no cache local.');
  }

  final pedido = await _pedidoComItensDoCache(row);
  if (!pedido.ehCredito) {
    throw Exception("Operação 'registo de pagamento' só é válida para pedidos a crédito.");
  }

  final saldoDevedor = pedido.total - pedido.valorPago;
  if (dto.valorPago > saldoDevedor) {
    throw Exception(
      'Pagamento excede o saldo. Valor: ${dto.valorPago}, saldo: $saldoDevedor',
    );
  }

  await _enqueuePedidoOperation(
    operacao: 'REGISTAR_PAGAMENTO',
    idPedido: idPedido,
    payload: dto.toJson(),
  );

  final novoValorPago = pedido.valorPago + dto.valorPago;
  final liquidado = novoValorPago >= pedido.total;
  final agora = DateTime.now();

  await _db.update(
    'pedido',
    {
      'valor_pago': novoValorPago,
      'status_pagamento': liquidado ? 'PAGO' : 'PARCIAL',
      'status_pedido': liquidado ? 'finalizado' : pedido.statusPedido,
      'data_liquidacao_credito': liquidado ? agora.toIso8601String() : null,
      'data_finalizacao': liquidado ? agora.toIso8601String() : null,
      'sync_status': 'pending_update',
      'updated_at': agora.toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [idPedido],
  );

  final pagamentoLocal = PagamentoCreditoModel(
    idPagamentoCredito: -agora.microsecondsSinceEpoch,
    referencia: 'PAG-LOCAL-${agora.millisecondsSinceEpoch}',
    idPedido: idPedido,
    idParcela: dto.idParcela,
    idTipoPagamento: dto.idTipoPagamento,
    idUsuario: dto.idUsuario,
    idDocumentoRecibo: -agora.microsecondsSinceEpoch,
    valorPago: dto.valorPago,
    dataPagamento: agora,
    observacoes: dto.observacoes,
  );

  return pagamentoLocal;
}

Future<List<ParcelaCreditoModel>> listarParcelas(int idPedido) async {
  final online = _connectivity.isOnline;

  if (online) {
    try {
      return await _service.listarParcelas(idPedido);
    } catch (e) {
      debugPrint('⚠️ PedidoRepository.listarParcelas online falhou: $e');
    }
  }

  // Cache local das parcelas será implementado no PedidoDao.
  return [];
}

Future<List<PagamentoCreditoModel>> listarPagamentosCredito(int idPedido) async {
  final online = _connectivity.isOnline;

  if (online) {
    try {
      return await _service.listarPagamentosCredito(idPedido);
    } catch (e) {
      debugPrint('⚠️ PedidoRepository.listarPagamentosCredito online falhou: $e');
    }
  }

  // Cache local dos pagamentos será implementado no PedidoDao.
  return [];
}

Future<List<PedidoModel>> listarEmDivida() async {
  final online = _connectivity.isOnline;

  if (online) {
    try {
      final pedidos = await _service.listarEmDivida();
      for (final p in pedidos) {
        await _upsertPedidoComItens(p);
      }
      return pedidos;
    } catch (e) {
      debugPrint('⚠️ PedidoRepository.listarEmDivida online falhou; usando cache: $e');
    }
  }

  final rows = await _db.query(
    'pedido',
    where: 'tipo_venda = ? AND deleted = 0',
    whereArgs: ['CREDITO'],
    orderBy: 'data_pedido DESC',
  );

  return Future.wait(rows.map(_pedidoComItensDoCache));
}



Future<Map<String, dynamic>> extractoCliente(int idCliente) async {
  final online = _connectivity.isOnline;

  if (online) {
    try {
      return await _service.extractoCliente(idCliente);
    } catch (e) {
      debugPrint(
        '⚠️ PedidoRepository.extractoCliente online falhou; calculando local: $e',
      );
    }
  }

  final rows = await _db.query(
    'pedido',
    where: 'id_cliente = ? AND tipo_venda = ? AND deleted = 0',
    whereArgs: [idCliente, 'CREDITO'],
  );

  double totalDivida = 0;
  double totalPago = 0;

  final linhas = <Map<String, dynamic>>[];

  for (final row in rows) {
    final p = PedidoModel.fromLocalDb(row);
    final saldo = p.total - p.valorPago;

    totalDivida += p.total;
    totalPago += p.valorPago;

    linhas.add({
      'idPedido': p.idPedido,
      'referencia': p.referencia,
      'total': p.total,
      'valorPago': p.valorPago,
      'saldo': saldo,
      'statusPagamento': p.statusPagamento,
      'idDocumentoFacturaCredito': p.idDocumentoFacturaCredito,
    });
  }

  return {
    'idCliente': idCliente,
    'totalDivida': totalDivida,
    'totalPago': totalPago,
    'saldo': totalDivida - totalPago,
    'linhas': linhas,
  };
}



}

