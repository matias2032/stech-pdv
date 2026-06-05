// lib/core/sync/sync_scheduler.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../connectivity/connectivity_service.dart';
import '../database/daos/sync_queue_dao.dart';
import '../database/daos/cliente_dao.dart';
import 'package:api_compartilhado/api_config.dart';
import 'package:api_compartilhado/models/cliente_model.dart';
import 'package:api_compartilhado/models/cliente_model.dart';
import 'package:api_compartilhado/services/cliente_service.dart';
import '../connectivity/connectivity_service.dart';
import '../database/daos/sync_queue_dao.dart';
import '../database/daos/cliente_dao.dart';
import '../database/daos/marca_dao.dart';
import '../database/daos/categoria_dao.dart';
import '../database/daos/produto_dao.dart';
import '../database/daos/servico_dao.dart';
import '../database/daos/pedido_dao.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import '../database/daos/documento_fiscal_dao.dart';
import 'package:api_compartilhado/models/documento_fiscal_model.dart';
import 'package:api_compartilhado/services/documento_fiscal_service.dart';

class SyncScheduler {
  SyncScheduler._();
  static final SyncScheduler instance = SyncScheduler._();

  ConnectivityService? _connectivity;
  SyncQueueDao?        _syncQueueDao;
  ClienteDao?          _clienteDao;
  ClienteService?      _clienteService;
  MarcaDao?          _marcaDao;
MarcaService?      _marcaService;
CategoriaDao?      _categoriaDao;
CategoriaService?  _categoriaService;
ProdutoDao?        _produtoDao;
ProdutoService?    _produtoService;
ServicoDao?     _servicoDao;
ServicoService? _servicoService;
PedidoDao?      _pedidoDao;
PedidoService?  _pedidoService;
DocumentoFiscalDao?     _documentoFiscalDao;
DocumentoFiscalService? _documentoFiscalService;

  StreamSubscription<bool>? _subscription;
  bool _syncEmCurso = false;

  // ── Inicialização ─────────────────────────────────────────────────

void init({
  required ConnectivityService connectivity,
  required SyncQueueDao        syncQueueDao,
  required ClienteDao          clienteDao,
  required ClienteService      clienteService,
  required MarcaDao            marcaDao,
  required MarcaService        marcaService,
  required CategoriaDao        categoriaDao,
  required CategoriaService    categoriaService,
  required ProdutoDao          produtoDao,
  required ProdutoService      produtoService,
  required ServicoDao     servicoDao,
required ServicoService servicoService,
required PedidoDao     pedidoDao,
required PedidoService pedidoService,
required DocumentoFiscalDao     documentoFiscalDao,
required DocumentoFiscalService documentoFiscalService,

}) {
  _connectivity      = connectivity;
  _syncQueueDao      = syncQueueDao;
  _clienteDao        = clienteDao;
  _clienteService    = clienteService;
  _marcaDao          = marcaDao;
  _marcaService      = marcaService;
  _categoriaDao      = categoriaDao;
  _categoriaService  = categoriaService;
  _produtoDao        = produtoDao;
  _produtoService    = produtoService;
    _produtoDao        = produtoDao;
  _produtoService    = produtoService;
  _servicoDao        = servicoDao;
  _servicoService    = servicoService;
  _pedidoDao     = pedidoDao;
_pedidoService = pedidoService;
_documentoFiscalDao     = documentoFiscalDao;
_documentoFiscalService = documentoFiscalService;

  _subscription = connectivity.isOnlineStream.listen((isOnline) {
    if (isOnline) {
      debugPrint('🔁 SyncScheduler — online detectado, a iniciar flush...');
      flushQueue();
    }
  });
  debugPrint('⚙️ SyncScheduler iniciado');
}

  // ── Flush da fila ─────────────────────────────────────────────────

  Future<void> flushQueue() async {
    if (_syncEmCurso) {
      debugPrint('⚙️ SyncScheduler — sync já em curso, ignorar');
      return;
    }
    _syncEmCurso = true;

    try {
      final pendentes = await _syncQueueDao!.getPending();
      if (pendentes.isEmpty) {
        debugPrint('✅ SyncScheduler — fila vazia, nada a sincronizar');
        return;
      }

      debugPrint('⚙️ SyncScheduler — ${pendentes.length} operação(ões) pendente(s)');

      for (final item in pendentes) {
        final id       = item['id']       as int;
        final entidade = item['entidade'] as String;
        final operacao = item['operacao'] as String;
        final payload  = jsonDecode(item['payload'] as String) as Map<String, dynamic>;

        try {
          await _processarOperacao(entidade, operacao, payload);
          await _syncQueueDao!.delete(id);
          debugPrint('✅ SyncScheduler — operação $id ($entidade/$operacao) sincronizada');
        } catch (e) {
          await _syncQueueDao!.incrementarTentativas(id);
          debugPrint('❌ SyncScheduler — operação $id falhou (tentativa incrementada): $e');
        }
      }
    } finally {
      _syncEmCurso = false;
    }
  }

  // ── Processar operação individual ─────────────────────────────────

  Future<void> _processarOperacao(
  String entidade,
  String operacao,
  Map<String, dynamic> payload,
) async {
  switch (entidade) {
    case 'cliente':
      await _processarCliente(operacao, payload);
    case 'marca':
      await _processarMarca(operacao, payload);
    case 'categoria':
      await _processarCategoria(operacao, payload);
    case 'produto':
      await _processarProduto(operacao, payload);
      case 'servico':
  await _processarServico(operacao, payload);
  case 'pedido':
  await _processarPedido(operacao, payload);
case 'documento_fiscal':
  throw Exception(
    'documento_fiscal não suporta operações offline. '
    'Todas as operações requerem ligação activa.',
  );
  await _processarDocumentoFiscal(operacao, payload);
    default:
      throw Exception('Entidade desconhecida: $entidade');
  }
}

  // ── Processar operações de cliente ────────────────────────────────

  Future<void> _processarCliente(
    String operacao,
    Map<String, dynamic> payload,
  ) async {
    final service = _clienteService!;
    final dao     = _clienteDao!;

    switch (operacao) {
      case 'CREATE':
        final localId = payload['localId'] as String?;
        final dto = ClienteRequestDTO(
          nome:      payload['nome']     as String?,
          apelido:   payload['apelido']  as String?,
          email:     payload['email']    as String?,
          nuit:      payload['nuit']     as String?,
          contacto:  payload['contacto'] as String?,
          morada:    payload['morada']   as String?,
          idPerfil:  payload['idPerfil'] as int,
        );
        final clienteCriado = await service.criar(dto);

        // Substituir registo local (ID temporário) pelo ID real do backend
        if (localId != null) {
          await dao.deleteByLocalId(localId);
        }
        await dao.upsert(clienteCriado.toLocalDb());
        break;

      case 'UPDATE':
        final id  = payload['id'] as int;
        final dto = ClienteRequestDTO(
          nome:      payload['nome']     as String?,
          apelido:   payload['apelido']  as String?,
          email:     payload['email']    as String?,
          nuit:      payload['nuit']     as String?,
          contacto:  payload['contacto'] as String?,
          morada:    payload['morada']   as String?,
          idPerfil:  payload['idPerfil'] as int,
        );
        final clienteEditado = await service.editar(id, dto);
        await dao.upsert(clienteEditado.toLocalDb());
        break;

      case 'DELETE':
        final id = payload['id'] as int;
        await service.excluir(id);
        // Já foi removido localmente no momento da operação offline
        break;

      default:
        throw Exception('Operação desconhecida para cliente: $operacao');
    }
  }

  // ── Processar operações de marca ──────────────────────────────────

Future<void> _processarMarca(
  String operacao,
  Map<String, dynamic> payload,
) async {
  final service = _marcaService!;
  final dao     = _marcaDao!;

  switch (operacao) {
    case 'CREATE':
      final localId = payload['localId'] as String?;
      final dto = MarcaRequestDTO(nomeMarca: payload['nomeMarca'] as String);
      final criada = await service.criarMarca(dto);
      if (localId != null) await dao.deleteByLocalId(localId);
      await dao.upsert(criada.toLocalDb());

    case 'UPDATE':
      final id  = payload['id'] as int;
      final dto = MarcaRequestDTO(nomeMarca: payload['nomeMarca'] as String);
      final editada = await service.atualizarMarca(id, dto);
      await dao.upsert(editada.toLocalDb());

    case 'DELETE':
      await service.deletarMarca(payload['id'] as int);

    default:
      throw Exception('Operação desconhecida para marca: $operacao');
  }
}

// ── Processar operações de categoria ──────────────────────────────

Future<void> _processarCategoria(
  String operacao,
  Map<String, dynamic> payload,
) async {
  final service = _categoriaService!;
  final dao     = _categoriaDao!;

  switch (operacao) {
    case 'CREATE':
      final localId = payload['localId'] as String?;
      final dto = CategoriaRequestDTO(
        nomeCategoria: payload['nomeCategoria'] as String,
        descricao:     payload['descricao']     as String?,
      );
      final criada = await service.criarCategoria(dto);
      if (localId != null) await dao.deleteByLocalId(localId);
      await dao.upsert(criada.toLocalDb());

    case 'UPDATE':
      final id  = payload['id'] as int;
      final dto = CategoriaRequestDTO(
        nomeCategoria: payload['nomeCategoria'] as String,
        descricao:     payload['descricao']     as String?,
      );
      final editada = await service.atualizarCategoria(id, dto);
      await dao.upsert(editada.toLocalDb());

    case 'DELETE':
      await service.deletarCategoria(payload['id'] as int);

    default:
      throw Exception('Operação desconhecida para categoria: $operacao');
  }
}

// ── Processar operações de produto ────────────────────────────────

Future<void> _processarProduto(
  String operacao,
  Map<String, dynamic> payload,
) async {
  final service = _produtoService!;
  final dao     = _produtoDao!;

  switch (operacao) {
    case 'CREATE':
      final localId = payload['localId'] as String?;
      final dto = ProdutoRequestModel(
        nomeProduto:       payload['nomeProduto']       as String,
        descricao:         payload['descricao']         as String?,
        preco:             (payload['preco']            as num).toDouble(),
        quantidadeEstoque: payload['quantidadeEstoque'] as int,
        precoPromocional:  payload['precoPromocional'] != null
            ? (payload['precoPromocional'] as num).toDouble()
            : null,
        categorias: (payload['categorias'] as List<dynamic>?)
                ?.map((e) => e as int).toList() ?? [],
        marcas: (payload['marcas'] as List<dynamic>?)
                ?.map((e) => e as int).toList() ?? [],
      );
      final criado = await service.criar(dto);
      if (localId != null) await dao.deleteByLocalId(localId);
      await dao.upsert(ProdutoModel.fromJson(
        {'idProduto': criado.idProduto, ...criado.toJson()},
      ).toLocalDb());

    case 'UPDATE':
      final id  = payload['id'] as int;
      final dto = ProdutoRequestModel(
        nomeProduto:       payload['nomeProduto']       as String,
        descricao:         payload['descricao']         as String?,
        preco:             (payload['preco']            as num).toDouble(),
        quantidadeEstoque: payload['quantidadeEstoque'] as int,
        precoPromocional:  payload['precoPromocional'] != null
            ? (payload['precoPromocional'] as num).toDouble()
            : null,
        categorias: (payload['categorias'] as List<dynamic>?)
                ?.map((e) => e as int).toList() ?? [],
        marcas: (payload['marcas'] as List<dynamic>?)
                ?.map((e) => e as int).toList() ?? [],
      );
      final editado = await service.atualizar(id, dto);
      await dao.upsert(editado.toLocalDb());

    case 'DELETE':
      // produto não tem delete directo no schema (usa ativo=0)
      // mas por consistência:
      await dao.delete(payload['id'] as int);

    default:
      throw Exception('Operação desconhecida para produto: $operacao');
  }
}

Future<void> _processarServico(
  String operacao,
  Map<String, dynamic> payload,
) async {
  final service = _servicoService!;
  final dao     = _servicoDao!;

  switch (operacao) {
    case 'CREATE':
      final localId = payload['localId'] as String?;
      final dto = ServicoRequestModel(
        nomeServico:   payload['nomeServico']   as String,
        descricao:     payload['descricao']     as String?,
        precoUnitario: (payload['precoUnitario'] as num).toDouble(),
        unidade:       payload['unidade']       as String,
      );
      final criado = await service.criar(dto);
      if (localId != null) await dao.deleteByLocalId(localId);
      await dao.upsert(criado.toLocalDb());

    case 'UPDATE':
      final id  = payload['id'] as int;
      final dto = ServicoRequestModel(
        nomeServico:   payload['nomeServico']   as String,
        descricao:     payload['descricao']     as String?,
        precoUnitario: (payload['precoUnitario'] as num).toDouble(),
        unidade:       payload['unidade']       as String,
      );
      final editado = await service.actualizar(id, dto);
      await dao.upsert(editado.toLocalDb());

    default:
      throw Exception('Operação desconhecida para serviço: $operacao');
  }
}

// ADICIONAR: método completo _processarPedido

Future<void> _processarPedido(
  String operacao,
  Map<String, dynamic> payload,
) async {
  final service = _pedidoService!;
  final dao     = _pedidoDao!;

  switch (operacao) {
    case 'CREATE':
      // Sincroniza o rascunho: envia ao backend e substitui o registo local
      final localId = payload['localId'] as String?;

      final dto = PedidoRequestModel(
        idUsuario:       payload['idUsuario']       as int,
        idTipoPagamento: payload['idTipoPagamento'] as int,
        pontoReferencia: payload['pontoReferencia'] as String?,
        observacoes:     payload['observacoes']     as String?,
        itensProduto: (payload['itensProduto'] as List<dynamic>? ?? [])
            .map((e) => ItemPedidoRequestModel(
                  idProduto:  (e as Map<String, dynamic>)['idProduto']  as int,
                  quantidade: e['quantidade'] as int,
                ))
            .toList(),
        itensServico: (payload['itensServico'] as List<dynamic>? ?? [])
            .map((e) => ItemServicoRequestModel(
                  idServico:   (e as Map<String, dynamic>)['idServico']  as int,
                  quantidade:  e['quantidade'] as int,
                  observacoes: e['observacoes'] as String?,
                ))
            .toList(),
      );

      final criado = await service.criarPedido(dto);

      // Substituir registo local (ID temporário) pelo pedido real
      if (localId != null) await dao.deleteByLocalId(localId);
      await dao.upsert(criado.toLocalDb());

      // Substituir itens locais temporários pelos itens reais
      await dao.deleteItensByPedido(criado.idPedido);
      final itens = criado.itensProduto.map((i) => {
            'id':             i.idItemPedido,
            'id_pedido':      criado.idPedido,
            'id_produto':     i.idProduto,
            'preco_unitario': i.precoUnitario,
            'quantidade':     i.quantidade,
            'subtotal':       i.subtotal,
          }).toList();
      if (itens.isNotEmpty) await dao.upsertAllItens(itens);

    case 'ADD_ITEM_PRODUTO':
      // Só chega aqui se o pedido já foi sincronizado (tem ID real)
      final idPedido = payload['idPedido'] as int;
      final dto = ItemPedidoRequestDTO(
        idProduto:  payload['idProduto']  as int,
        quantidade: payload['quantidade'] as int,
      );
      final atualizado = await service.adicionarItemProduto(idPedido, dto);
      await dao.upsert(atualizado.toLocalDb());

    case 'ADD_ITEM_SERVICO':
      final idPedido = payload['idPedido'] as int;
      final dto = ItemServicoRequestDTO(
        idServico:   payload['idServico']   as int,
        quantidade:  payload['quantidade']  as int,
        observacoes: payload['observacoes'] as String?,
      );
      final atualizado = await service.adicionarItemServico(idPedido, dto);
      await dao.upsert(atualizado.toLocalDb());

    case 'EDIT_ITEM_PRODUTO':
      final atualizado = await service.editarQuantidadeItemProduto(
        payload['idPedido']     as int,
        payload['idItemPedido'] as int,
        EditarItemRequestDTO(novaQuantidade: payload['novaQuantidade'] as int),
      );
      await dao.upsert(atualizado.toLocalDb());

    case 'EDIT_ITEM_SERVICO':
      final atualizado = await service.editarQuantidadeItemServico(
        payload['idPedido']      as int,
        payload['idItemServico'] as int,
        EditarItemRequestDTO(novaQuantidade: payload['novaQuantidade'] as int),
      );
      await dao.upsert(atualizado.toLocalDb());

    case 'REMOVE_ITEM_PRODUTO':
      final atualizado = await service.eliminarItemProduto(
        payload['idPedido']     as int,
        payload['idItemPedido'] as int,
      );
      await dao.upsert(atualizado.toLocalDb());

    case 'REMOVE_ITEM_SERVICO':
      final atualizado = await service.eliminarItemServico(
        payload['idPedido']      as int,
        payload['idItemServico'] as int,
      );
      await dao.upsert(atualizado.toLocalDb());

    default:
      throw Exception('Operação desconhecida para pedido: $operacao');
  }
}

Future<void> _processarDocumentoFiscal(
  String operacao,
  Map<String, dynamic> payload,
) async {
  final service = _documentoFiscalService!;
  final dao     = _documentoFiscalDao!;

  switch (operacao) {
    case 'ANULAR':
      final anulado = await service.anular(
        id:             payload['id']             as int,
        motivoAnulacao: payload['motivoAnulacao'] as String,
      );
      await dao.upsert(anulado.toLocalDb());

    default:
      throw Exception('Operação desconhecida para documento_fiscal: $operacao');
  }
}



  // ── Limpeza ───────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}