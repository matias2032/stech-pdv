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
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

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
  Database get _db => LocalDatabase.instance.db;

  StreamSubscription<bool>? _subscription;
  
  bool _syncEmCurso = false;

    final Map<String, int> _idMapping = {};

    


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


})

 {
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
    debugPrint('🔁 SyncScheduler — online detectado, aguardando estabilização...');
    // Aguarda 8 segundos antes de tentar — dá tempo ao HikariPool de reconectar ao Neon
    Future.delayed(const Duration(seconds: 8), () {
      if (_connectivity?.isOnline ?? false) {  // confirma que ainda está online
        flushQueue();
      }
    });
  }
});
  debugPrint('⚙️ SyncScheduler iniciado');
}

  // ── Flush da fila ─────────────────────────────────────────────────

  // Substituir flushQueue completo
// ── Flush da fila ─────────────────────────────────────────────────

  Future<void> flushQueue() async {
    if (_syncEmCurso) {
      debugPrint('⚙️ SyncScheduler — sync já em curso, ignorar');
      return;
    }
    _syncEmCurso = true;

    await Future.delayed(const Duration(seconds: 5));

    try {
      // Limpa o mapeamento de IDs temporários no início de cada flush
      _idMapping.clear();

      final pendentes = await _syncQueueDao!.getPending();
      if (pendentes.isEmpty) {
        debugPrint('✅ SyncScheduler — fila vazia, nada a sincronizar');
        return;
      }

      debugPrint('⚙️ SyncScheduler — ${pendentes.length} operação(ões) a enviar via batch');

      // ── PASSAGEM 1: pedido/CREATE ─────────────────────────────────
      // Estes precisam de ser processados primeiro para que _idMapping
      // seja populado antes de resolver dependências (ADD_ITEM_*, FINALIZAR).
      final creates = pendentes.where(
        (item) =>
            item['entidade'] == 'pedido' && item['operacao'] == 'CREATE',
      ).toList();

      if (creates.isNotEmpty) {
        await _enviarEProcessarLote(creates);
      }

      // ── PASSAGEM 2: restantes (já com _idMapping populado) ─────────
      final restantes = pendentes.where(
        (item) =>
            !(item['entidade'] == 'pedido' && item['operacao'] == 'CREATE'),
      ).toList();

      if (restantes.isNotEmpty) {
        await _enviarEProcessarLote(restantes);
      }
    } catch (e) {
      debugPrint('❌ SyncScheduler — erro no batch: $e');
      // Não incrementa tentativas aqui — erro de rede, não de lógica
    } finally {
      _syncEmCurso = false;
    }
  }

  // ── Monta, envia e processa um lote (batch) de itens da fila ──────
Future<void> _enviarEProcessarLote(
    List<Map<String, dynamic>> itens,
  ) async {
    final operacoes  = <Map<String, dynamic>>[];
    final queueIdsEnviados = <int>[]; // paralelo a `operacoes`, mesma ordem/índice
    final idsSaltados = <int>{};

    for (final item in itens) {
      var payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;
      final entidade = item['entidade'] as String;
      final operacao = item['operacao'] as String;

      if (entidade == 'pedido' &&
          (operacao == 'ADD_ITEM_PRODUTO' ||
              operacao == 'ADD_ITEM_SERVICO' ||
              operacao == 'FINALIZAR')) {
        try {
          payload = await _resolverIdsPedido(payload);
        } catch (_) {
          idsSaltados.add(item['id'] as int);
          continue;
        }
      }

      operacoes.add({
        'entidade': entidade,
        'operacao': operacao,
        'localId':  payload['localId'] as String?,
        'id':       payload['id'],
        'payload':  payload,
      });
      queueIdsEnviados.add(item['id'] as int);
    }

    if (operacoes.isEmpty) {
      for (final item in itens) {
        final queueId = item['id'] as int;
        if (idsSaltados.contains(queueId)) {
          debugPrint(
            '⏭️ SyncScheduler — ${item['entidade']}/${item['operacao']} '
            'adiado (pedido pai pendente)',
          );
        }
      }
      debugPrint('⚙️ SyncScheduler — todas as operações deste lote adiadas');
      return;
    }

    // ── Enviar batch ao backend ───────────────────────────────────
    final response = await http.post(
      Uri.parse(ApiConfig.syncBatchUrl),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'operacoes': operacoes}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      debugPrint('❌ SyncScheduler — batch rejeitado HTTP ${response.statusCode}');
      for (final item in itens) {
        await _syncQueueDao!.incrementarTentativas(item['id'] as int);
      }
      return;
    }

    // ── Processar resultados individuais ──────────────────────────
    final body       = jsonDecode(response.body) as Map<String, dynamic>;
    final resultados = (body['resultados'] as List<dynamic>?) ?? [];

    // Casamento por posição: resultados[i] corresponde a operacoes[i],
    // que corresponde a queueIdsEnviados[i]. O backend processa
    // sequencialmente e devolve exactamente um resultado por operação,
    // na mesma ordem — não depende de localId/idReal estarem presentes.
    final resultadoPorQueueId = <int, Map<String, dynamic>>{};
    for (var i = 0; i < resultados.length && i < queueIdsEnviados.length; i++) {
      resultadoPorQueueId[queueIdsEnviados[i]] = resultados[i] as Map<String, dynamic>;
    }

    for (final item in itens) {
      final queueId   = item['id']       as int;
      final entidade  = item['entidade'] as String;
      final operacao  = item['operacao'] as String;
      final payload   = jsonDecode(item['payload'] as String) as Map<String, dynamic>;
      final localId   = payload['localId'] as String?;

      final resultado = resultadoPorQueueId[queueId];
      final sucesso   = resultado?['sucesso'] as bool? ?? false;

      if (sucesso) {
        final idReal = resultado?['idReal'] as int?;
        try {
          await _actualizarDaoLocal(
            entidade: entidade,
            operacao: operacao,
            payload:  payload,
            localId:  localId,
            idReal:   idReal,
          );
        } catch (e) {
          debugPrint('⚠️ SyncScheduler — erro ao actualizar DAO local ($entidade): $e');
        }
        await _syncQueueDao!.delete(queueId);
        debugPrint('✅ SyncScheduler — $entidade/$operacao sincronizado'
            '${idReal != null ? " (idReal: $idReal)" : ""}');
      } else if (idsSaltados.contains(queueId)) {
        debugPrint('⏭️ SyncScheduler — $entidade/$operacao adiado (pedido pai pendente)');
      } else {
        await _syncQueueDao!.incrementarTentativas(queueId);
        debugPrint('❌ SyncScheduler — $entidade/$operacao falhou: ${resultado?["erro"]}');
      }
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

      case 'FINALIZAR':
  final idPedido = payload['idPedido'] as int;
  final dto = FinalizarPedidoRequestDTO(
    idTipoPagamento:        payload['idTipoPagamento']        as int,
    valorPago:              (payload['valorPago'] as num).toDouble(),
    observacoes:            payload['observacoes']            as String?,
    idCliente:              payload['idCliente']              as int?,
    nomeClienteSingular:    payload['nomeClienteSingular']    as String?,
    apelidoClienteSingular: payload['apelidoClienteSingular'] as String?,
  );
  final finalizado = await _pedidoService!.finalizarPedido(idPedido, dto);
  await _pedidoDao!.upsert(finalizado.toLocalDb());

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


Future<void> _actualizarDaoLocal({
  required String entidade,
  required String operacao,
  required Map<String, dynamic> payload,
  required String? localId,
  required int? idReal,
}) async {
  switch (entidade) {
    case 'cliente':
      if (operacao == 'CREATE' && localId != null && idReal != null) {
        await _clienteDao!.deleteByLocalId(localId);
        final existente = await _clienteDao!.getById(idReal);
        if (existente != null) await _clienteDao!.marcarSynced(idReal);
      }

    case 'marca':
      if (operacao == 'CREATE' && localId != null && idReal != null) {
        await _marcaDao!.deleteByLocalId(localId);
      }

    case 'categoria':
      if (operacao == 'CREATE' && localId != null && idReal != null) {
        await _categoriaDao!.deleteByLocalId(localId);
      }

    case 'produto':
      if (operacao == 'CREATE' && localId != null && idReal != null) {
        await _produtoDao!.deleteByLocalId(localId);
      }

    case 'servico':
      if (operacao == 'CREATE' && localId != null && idReal != null) {
        await _servicoDao!.deleteByLocalId(localId);
      }

case 'pedido':
      if (operacao == 'CREATE' && localId != null && idReal != null) {
        // 1. Guarda o tempId antes de apagar
        final tempRow = await _pedidoDao!.getByLocalId(localId);
        final tempId  = tempRow?['id'] as int?;

        // 2. Apaga o registo temporário
        await _pedidoDao!.deleteByLocalId(localId);

        // 3. Vai buscar o pedido real ao backend
        try {
          final pedidoReal = await _pedidoService!.buscarPorId(idReal);
          await _pedidoDao!.upsert(pedidoReal.toLocalDb());

          // 4. Migra itens temporários para o ID real
          if (tempId != null) {
            await _db.rawUpdate(
              'UPDATE item_pedido SET id_pedido = ? WHERE id_pedido = ?',
              [idReal, tempId],
            );
            await _db.rawUpdate(
              'UPDATE item_pedido_servico SET id_pedido = ? WHERE id_pedido = ?',
              [idReal, tempId],
            );
          }
        } catch (e) {
          debugPrint('⚠️ SyncScheduler — pull pedido $idReal falhou: $e');
        }
         if (tempId != null) {
          _idMapping['$tempId'] = idReal;
        }
      }

       if (operacao == 'FINALIZAR') {
    final idPedidoReal = payload['idPedido'] as int?;
    if (idPedidoReal != null) {
      try {
        final pedidoReal = await _pedidoService!.buscarPorId(idPedidoReal);
        await _pedidoDao!.upsert(pedidoReal.toLocalDb());
        // Actualiza também os itens com dados reais do backend
        await _pedidoDao!.deleteItensByPedido(pedidoReal.idPedido);
        final itensProduto = pedidoReal.itensProduto.map((i) => {
          'id':             i.idItemPedido,
          'id_pedido':      pedidoReal.idPedido,
          'id_produto':     i.idProduto,
          'preco_unitario': i.precoUnitario,
          'quantidade':     i.quantidade,
          'subtotal':       i.subtotal,
        }).toList();
        if (itensProduto.isNotEmpty) {
          await _pedidoDao!.upsertAllItens(itensProduto);
        }
        await _pedidoDao!.deleteItensServicoPorPedido(pedidoReal.idPedido);
        final itensServico = pedidoReal.itensServico.map((i) => {
          'id':             i.idItemServico,
          'id_pedido':      pedidoReal.idPedido,
          'id_servico':     i.idServico,
          'preco_unitario': i.precoUnitario,
          'quantidade':     i.quantidade,
          'subtotal':       i.subtotal,
          'observacoes':    i.observacoes,
        }).toList();
        if (itensServico.isNotEmpty) {
          await _pedidoDao!.upsertAllItensServico(itensServico);
        }
      } catch (e) {
        debugPrint('⚠️ SyncScheduler — pull após FINALIZAR falhou: $e');
      }
    }
  }
  }
}


Future<Map<String, dynamic>> _resolverIdsPedido(
    Map<String, dynamic> payload,
  ) async {
    final idPedidoLocal = payload['idPedidoLocal'] as String?;
    if (idPedidoLocal == null) return payload; // já tem idPedido real

    // 1. Verifica primeiro o mapeamento em memória, populado nesta
    //    mesma passagem do flush (ex: pedido criado na Passagem 1).
    final idRealMapeado = _idMapping[idPedidoLocal];
    if (idRealMapeado != null) {
      final resolvido = Map<String, dynamic>.from(payload);
      resolvido['idPedido'] = idRealMapeado;
      resolvido.remove('idPedidoLocal');
      return resolvido;
    }

    // 2. Fallback: procura no SQLite (caso o CREATE já tenha sido
    //    sincronizado num flush anterior).
    final tempId = int.tryParse(idPedidoLocal);
    if (tempId == null) return payload;

    final row = await _pedidoDao!.getById(tempId);
    if (row != null) {
      final idReal = row['id'] as int?;
      if (idReal != null && idReal > 0) {
        final resolvido = Map<String, dynamic>.from(payload);
        resolvido['idPedido'] = idReal;
        resolvido.remove('idPedidoLocal');
        return resolvido;
      }
    }
    // Pedido ainda não sincronizado — adiar esta operação
    throw Exception('Pedido temporário $idPedidoLocal ainda não sincronizado');
  }



  // ── Limpeza ───────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}