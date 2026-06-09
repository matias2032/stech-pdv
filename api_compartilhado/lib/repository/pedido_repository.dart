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

class PedidoRepository {
  PedidoRepository({
    required PedidoService service,
    required PedidoDao dao,
    required SyncQueueDao syncQueueDao,
    required ConnectivityService connectivity,
    required ProdutoDao produtoDao
  })  : _service = service,
        _dao = dao,
        _syncQueueDao = syncQueueDao,
        _connectivity = connectivity,
        _produtoDao = produtoDao;

  final PedidoService _service;
  final PedidoDao _dao;
  final SyncQueueDao _syncQueueDao;
  final ConnectivityService _connectivity;
  final ProdutoDao _produtoDao;
  Database get _db => LocalDatabase.instance.db;

  static const _uuid = Uuid();

  // ── Upsert completo (pedido + itens de produto) ───────────────────

  Future<void> _upsertPedidoComItens(PedidoModel m) async {
    await _dao.upsert(m.toLocalDb());
    await _dao.deleteItensByPedido(m.idPedido);
    final itens = m.itensProduto.map((i) => {
          'id':             i.idItemPedido,
          'id_pedido':      m.idPedido,
          'id_produto':     i.idProduto,
          'preco_unitario': i.precoUnitario,
          'quantidade':     i.quantidade,
          'subtotal':       i.subtotal,
        }).toList();
    if (itens.isNotEmpty) await _dao.upsertAllItens(itens);
  }

  // ── Leitura ───────────────────────────────────────────────────────

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
    return row == null ? null : PedidoModel.fromLocalDb(row);
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
    return rows.map(PedidoModel.fromLocalDb).toList();
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
    return rows.map(PedidoModel.fromLocalDb).toList();
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
  // Offline — lê do SQLite
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

  // ── Escrita — todas requerem ligação ──────────────────────────────

// SUBSTITUIR: criarPedido

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

    // Offline — guarda rascunho localmente
    final localId = _uuid.v4();
final tempId  = -(DateTime.now().millisecondsSinceEpoch);

// Calcula total estimado a partir dos itens (preço 0 por ora)
final local = PedidoModel(
  idPedido:        tempId,
  referencia:      'RASCUNHO-${localId.substring(0, 6).toUpperCase()}',
  idUsuario:       dto.idUsuario,
  idTipoPagamento: dto.idTipoPagamento,
  statusPedido:    'rascunho',
  total:           0,
  valorPago:       0,
  pontoReferencia: dto.pontoReferencia,
  observacoes:     dto.observacoes,
  dataPedido:      DateTime.now(),
  itensProduto:    const [],
  itensServico:    const [],
);
await _dao.upsert({...local.toLocalDb(), 'local_id': localId, 'sync_status': 'pending'});

// Guarda itens iniciais do request
for (final item in dto.itensProduto) {
  final itemLocal = {
    'id':             -(DateTime.now().microsecondsSinceEpoch + item.idProduto),
    'id_pedido':      tempId,
    'id_produto':     item.idProduto,
    'preco_unitario': 0.0,
    'quantidade':     item.quantidade,
    'subtotal':       0.0,
  };
  await _dao.upsertItem(itemLocal);
  await _produtoDao.decrementarEstoque(item.idProduto, item.quantidade);
}

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

// SUBSTITUIR: adicionarItemProduto

  Future<PedidoModel> adicionarItemProduto(
    int idPedido,
    ItemPedidoRequestDTO dto,
  ) async {
    if (_connectivity.isOnline) {
      final m = await _service.adicionarItemProduto(idPedido, dto);
      await _upsertPedidoComItens(m);
      return m;
    }

    // Offline — guarda item localmente e enfileira
final itemLocal = {
  'id':             -(DateTime.now().millisecondsSinceEpoch),
  'id_pedido':      idPedido,
  'id_produto':     dto.idProduto,
  'preco_unitario': 0.0,
  'quantidade':     dto.quantidade,
  'subtotal':       0.0,
};
await _dao.upsertItem(itemLocal);

// Desconta estoque local imediatamente
await _produtoDao.decrementarEstoque(dto.idProduto, dto.quantidade);

await _syncQueueDao.enqueue('pedido', 'ADD_ITEM_PRODUTO', {
  'idPedido':      idPedido.isNegative ? null        : idPedido,
  'idPedidoLocal': idPedido.isNegative ? '$idPedido' : null,
  'idProduto':     dto.idProduto,
  'quantidade':    dto.quantidade,
});

    final row = await _dao.getById(idPedido);
    return row != null
        ? PedidoModel.fromLocalDb(row)
        : _pedidoVazio(idPedido);
  }

// SUBSTITUIR: adicionarItemServico

  Future<PedidoModel> adicionarItemServico(
    int idPedido,
    ItemServicoRequestDTO dto,
  ) async {
    if (_connectivity.isOnline) {
      final m = await _service.adicionarItemServico(idPedido, dto);
      await _upsertPedidoComItens(m);
      return m;
    }

await _syncQueueDao.enqueue('pedido', 'ADD_ITEM_SERVICO', {
  'idPedido':      idPedido.isNegative ? null        : idPedido,
  'idPedidoLocal': idPedido.isNegative ? '$idPedido' : null,
  'idServico':     dto.idServico,
  'quantidade':    dto.quantidade,
  'observacoes':   dto.observacoes,
});

    final row = await _dao.getById(idPedido);
    return row != null
        ? PedidoModel.fromLocalDb(row)
        : _pedidoVazio(idPedido);
  }

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
    return row != null ? PedidoModel.fromLocalDb(row) : _pedidoVazio(idPedido);
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
    return row != null ? PedidoModel.fromLocalDb(row) : _pedidoVazio(idPedido);
  }

  Future<PedidoModel> eliminarItemProduto(int idPedido, int idItemPedido) async {
    if (_connectivity.isOnline) {
      final m = await _service.eliminarItemProduto(idPedido, idItemPedido);
      await _upsertPedidoComItens(m);
      return m;
    }

    await _dao.deleteItensByPedido(idItemPedido); // remove localmente
    await _syncQueueDao.enqueue('pedido', 'REMOVE_ITEM_PRODUTO', {
      'idPedido':     idPedido,
      'idItemPedido': idItemPedido,
    });

    final row = await _dao.getById(idPedido);
    return row != null ? PedidoModel.fromLocalDb(row) : _pedidoVazio(idPedido);
  }

 Future<PedidoModel> eliminarItemServico(int idPedido, int idItemServico) async {
    if (_connectivity.isOnline) {
      final m = await _service.eliminarItemServico(idPedido, idItemServico);
      await _upsertPedidoComItens(m);
      return m;
    }

    await _syncQueueDao.enqueue('pedido', 'REMOVE_ITEM_SERVICO', {
      'idPedido':      idPedido,
      'idItemServico': idItemServico,
    });

    final row = await _dao.getById(idPedido);
    return row != null ? PedidoModel.fromLocalDb(row) : _pedidoVazio(idPedido);
  }

  Future<PedidoModel> finalizarPedido(
    int idPedido,
    FinalizarPedidoRequestDTO dto,
  ) async {
    _requireOnline('finalizar pedido');
    final m = await _service.finalizarPedido(idPedido, dto);
    await _upsertPedidoComItens(m);
    return m;
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

  // Offline — marca localmente e restaura estoque
  final itens = await _dao.getItensByPedido(idPedido);
  for (final item in itens) {
    final idProduto = item['id_produto'] as int?;
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

Future<PedidoModel> _pedidoComItensDoCache(Map<String, dynamic> row) async {
  final pedido = PedidoModel.fromLocalDb(row);
  final itensRows = await _dao.getItensByPedido(pedido.idPedido);
  final itens = itensRows.map((r) => ItemPedidoModel(
    idItemPedido:  (r['id'] as int?) ?? 0,
    idProduto:     (r['id_produto'] as int?) ?? 0,
    nomeProduto:   'Produto #${r['id_produto']}', // nome não está no cache
    quantidade:    (r['quantidade'] as int?) ?? 0,
    precoUnitario: (r['preco_unitario'] as num?)?.toDouble() ?? 0.0,
    subtotal:      (r['subtotal'] as num?)?.toDouble() ?? 0.0,
  )).toList();
  return pedido.copyWith(itensProduto: itens);
}

  // ── Guard offline ─────────────────────────────────────────────────

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
        statusPedido:    'rascunho',
        total:           0,
        valorPago:       0,
        dataPedido:      DateTime.now(),
      );

}