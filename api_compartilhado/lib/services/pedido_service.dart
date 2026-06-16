import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/pedido_model.dart';
import '../models/pedido_request.dart';
import '../models/api_response.dart';

// ─── DTOs locais (inline) ────────────────────────────────────────────────────

class ItemPedidoRequestDTO {
  final int idProduto;
  final int quantidade;

  const ItemPedidoRequestDTO({
    required this.idProduto,
    required this.quantidade,
  });

  Map<String, dynamic> toJson() => {
        'idProduto': idProduto,
        'quantidade': quantidade,
      };
}

class ItemServicoRequestDTO {
  final int idServico;
  final int quantidade;
  final String? observacoes;

  const ItemServicoRequestDTO({
    required this.idServico,
    required this.quantidade,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        'idServico': idServico,
        'quantidade': quantidade,
        if (observacoes != null) 'observacoes': observacoes,
      };
}

class EditarItemRequestDTO {
  final int novaQuantidade;

  const EditarItemRequestDTO({required this.novaQuantidade});

  Map<String, dynamic> toJson() => {'novaQuantidade': novaQuantidade};
}

class FinalizarPedidoRequestDTO {
  final int idTipoPagamento;
  final double valorPago;
  final String? observacoes;
  final int? idCliente;
  final String? nomeClienteSingular;
  final String? apelidoClienteSingular;

  const FinalizarPedidoRequestDTO({
    required this.idTipoPagamento,
    required this.valorPago,
    this.observacoes,
    this.idCliente,
    this.nomeClienteSingular,
    this.apelidoClienteSingular,
  });

  Map<String, dynamic> toJson() => {
    'idTipoPagamento': idTipoPagamento,
    'valorPago': valorPago,
    if (observacoes != null && observacoes!.isNotEmpty) 'observacoes': observacoes,
    if (idCliente != null) 'idCliente': idCliente,
    if (nomeClienteSingular != null) 'nomeClienteSingular': nomeClienteSingular,
    if (apelidoClienteSingular != null) 'apelidoClienteSingular': apelidoClienteSingular,
  };
}

class CancelamentoPedidoRequestDTO {
  final int idUsuarioCancelou;
  final String? motivo;

  const CancelamentoPedidoRequestDTO({
    required this.idUsuarioCancelou,
    this.motivo,
  });

  Map<String, dynamic> toJson() => {
        'idUsuarioCancelou': idUsuarioCancelou,
        if (motivo != null) 'motivo': motivo,
      };
}

class TipoPagamentoResponseDTO {
  final int idTipoPagamento;
  final String tipoPagamento;

  const TipoPagamentoResponseDTO({
    required this.idTipoPagamento,
    required this.tipoPagamento,
  });

  factory TipoPagamentoResponseDTO.fromJson(Map<String, dynamic> json) =>
      TipoPagamentoResponseDTO(
        idTipoPagamento: json['idTipoPagamento'] as int,
        tipoPagamento: json['tipoPagamento'] as String,
      );
}

// ─── Excepções de domínio ────────────────────────────────────────────────────

class PedidoNaoEncontradoException implements Exception {
  final int idPedido;
  PedidoNaoEncontradoException(this.idPedido);

  @override
  String toString() => 'Pedido $idPedido não encontrado.';
}

class StatusPedidoInvalidoException implements Exception {
  final String statusActual;
  final String operacao;
  StatusPedidoInvalidoException(this.statusActual, this.operacao);

  @override
  String toString() =>
      'Operação "$operacao" inválida para pedido com status "$statusActual".';
}

class EstoqueInsuficienteException implements Exception {
  final String nomeProduto;
  final int estoqueActual;
  final int quantidadeSolicitada;
  EstoqueInsuficienteException(
      this.nomeProduto, this.estoqueActual, this.quantidadeSolicitada);

  @override
  String toString() =>
      'Estoque insuficiente para "$nomeProduto": '
      'disponível $estoqueActual, solicitado $quantidadeSolicitada.';
}

class ItemNaoPertenceAoPedidoException implements Exception {
  final int idItem;
  final int idPedido;
  ItemNaoPertenceAoPedidoException(this.idItem, this.idPedido);

  @override
  String toString() => 'Item $idItem não pertence ao pedido $idPedido.';
}

// ════════════════════════════════════════════════════════════════════════════
// PedidoService
// Espelho completo de PedidoService.java / PedidoController.java
// ════════════════════════════════════════════════════════════════════════════

class PedidoService {
  // Reutiliza o cliente HTTP entre chamadas para melhor performance
  final http.Client _client;

  PedidoService({http.Client? client}) : _client = client ?? http.Client();

  // ── headers padrão ────────────────────────────────────────────────────────

  Map<String, String> get _headers => ApiConfig.defaultHeaders;

  // ── helper: URL base dos pedidos ─────────────────────────────────────────

  String get _baseUrl => ApiConfig.pedidosUrl;

  // ── helper: lança excepção de domínio a partir da resposta HTTP ───────────

  Never _throwFromResponse(http.Response res) {
    final body = res.body;
    debugPrint('❌ PedidoService — ${res.statusCode}: $body');

    // Tenta extrair mensagem estruturada da API
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final msg = (json['message'] ?? json['error'] ?? body).toString();

      final lower = msg.toLowerCase();

if (lower.contains('crédito') || lower.contains('credito')) {
  throw Exception('Erro de crédito: $msg');
}

if (lower.contains('parcela')) {
  throw Exception('Erro de parcela: $msg');
}

if (lower.contains('saldo')) {
  throw Exception('Erro de saldo: $msg');
}

      if (res.statusCode == 404) throw PedidoNaoEncontradoException(0);
      if (res.statusCode == 409 || msg.toLowerCase().contains('estoque')) {
        throw EstoqueInsuficienteException(msg, 0, 0);
      }
      throw Exception('Erro ${res.statusCode}: $msg');
    } catch (e) {
      if (e is PedidoNaoEncontradoException ||
          e is EstoqueInsuficienteException) rethrow;
      throw Exception('Erro ${res.statusCode}: $body');
    }
  }

  // ── helper: parse de PedidoModel ─────────────────────────────────────────

  PedidoModel _parsePedido(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return PedidoModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    _throwFromResponse(res);
  }

  // ════════════════════════════════════════════════════════════════════════
  // a) CRIAR PEDIDO
  // POST /api/pedidos
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel> criarPedido(PedidoRequestModel dto) async {
    // debugPrint('📦 PedidoService.criarPedido — utilizador ${dto.idUsuario}');

    final res = await _client
        .post(
          Uri.parse(_baseUrl),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parsePedido(res);
  }

  // ════════════════════════════════════════════════════════════════════════
  // b) ADICIONAR ITEM DE PRODUTO
  // POST /api/pedidos/{idPedido}/itens/produto
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel> adicionarItemProduto(
    int idPedido,
    ItemPedidoRequestDTO dto,
  ) async {
    debugPrint(
        '📦 PedidoService.adicionarItemProduto — pedido $idPedido, produto ${dto.idProduto}');

    final res = await _client
        .post(
          Uri.parse('$_baseUrl/$idPedido/itens/produto'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parsePedido(res);
  }

  // ════════════════════════════════════════════════════════════════════════
  // c) ADICIONAR ITEM DE SERVIÇO
  // POST /api/pedidos/{idPedido}/itens/servico
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel> adicionarItemServico(
    int idPedido,
    ItemServicoRequestDTO dto,
  ) async {
    debugPrint(
        '📦 PedidoService.adicionarItemServico — pedido $idPedido, serviço ${dto.idServico}');

    final res = await _client
        .post(
          Uri.parse('$_baseUrl/$idPedido/itens/servico'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parsePedido(res);
  }

  // ════════════════════════════════════════════════════════════════════════
  // d) EDITAR QUANTIDADE DE ITEM DE PRODUTO
  // PATCH /api/pedidos/{idPedido}/itens/produto/{idItemPedido}
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel> editarQuantidadeItemProduto(
    int idPedido,
    int idItemPedido,
    EditarItemRequestDTO dto,
  ) async {
    debugPrint(
        '✏️  PedidoService.editarQuantidadeItemProduto — pedido $idPedido, item $idItemPedido');

    final res = await _client
        .patch(
          Uri.parse('$_baseUrl/$idPedido/itens/produto/$idItemPedido'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parsePedido(res);
  }

  // ════════════════════════════════════════════════════════════════════════
  // e) EDITAR QUANTIDADE DE ITEM DE SERVIÇO
  // PATCH /api/pedidos/{idPedido}/itens/servico/{idItemServico}
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel> editarQuantidadeItemServico(
    int idPedido,
    int idItemServico,
    EditarItemRequestDTO dto,
  ) async {
    debugPrint(
        '✏️  PedidoService.editarQuantidadeItemServico — pedido $idPedido, item $idItemServico');

    final res = await _client
        .patch(
          Uri.parse('$_baseUrl/$idPedido/itens/servico/$idItemServico'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parsePedido(res);
  }

  // ════════════════════════════════════════════════════════════════════════
  // f) ELIMINAR ITEM DE PRODUTO
  // DELETE /api/pedidos/{idPedido}/itens/produto/{idItemPedido}
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel> eliminarItemProduto(
    int idPedido,
    int idItemPedido,
  ) async {
    debugPrint(
        '🗑️  PedidoService.eliminarItemProduto — pedido $idPedido, item $idItemPedido');

    final res = await _client
        .delete(
          Uri.parse('$_baseUrl/$idPedido/itens/produto/$idItemPedido'),
          headers: _headers,
        )
        .timeout(ApiConfig.timeout);

    return _parsePedido(res);
  }

  // ════════════════════════════════════════════════════════════════════════
  // g) ELIMINAR ITEM DE SERVIÇO
  // DELETE /api/pedidos/{idPedido}/itens/servico/{idItemServico}
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel> eliminarItemServico(
    int idPedido,
    int idItemServico,
  ) async {
    debugPrint(
        '🗑️  PedidoService.eliminarItemServico — pedido $idPedido, item $idItemServico');

    final res = await _client
        .delete(
          Uri.parse('$_baseUrl/$idPedido/itens/servico/$idItemServico'),
          headers: _headers,
        )
        .timeout(ApiConfig.timeout);

    return _parsePedido(res);
  }

  // ════════════════════════════════════════════════════════════════════════
  // h) FINALIZAR PEDIDO
  // POST /api/pedidos/{idPedido}/finalizar
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel> finalizarPedido(
    int idPedido,
    FinalizarPedidoRequestDTO dto,
  ) async {
    debugPrint('✅ PedidoService.finalizarPedido — pedido $idPedido');

    final res = await _client
        .post(
          Uri.parse('$_baseUrl/$idPedido/finalizar'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parsePedido(res);
  }

  // ════════════════════════════════════════════════════════════════════════
  // i) CANCELAR PEDIDO
  // POST /api/pedidos/{idPedido}/cancelar  → 204 No Content
  // ════════════════════════════════════════════════════════════════════════

  Future<void> cancelarPedido(
    int idPedido,
    CancelamentoPedidoRequestDTO dto,
  ) async {
    debugPrint('❌ PedidoService.cancelarPedido — pedido $idPedido');

    final res = await _client
        .post(
          Uri.parse('$_baseUrl/$idPedido/cancelar'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    if (res.statusCode != 204 && res.statusCode != 200) {
      _throwFromResponse(res);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // CONSULTAS
  // ════════════════════════════════════════════════════════════════════════

  // ── GET /api/pedidos/{idPedido} ───────────────────────────────────────────

  Future<PedidoModel> buscarPorId(int idPedido) async {
    debugPrint('🔍 PedidoService.buscarPorId — $idPedido');

    final res = await _client
        .get(Uri.parse('$_baseUrl/$idPedido'), headers: _headers)
        .timeout(ApiConfig.timeout);

    return _parsePedido(res);
  }

  // ── GET /api/pedidos/usuario/{idUsuario} ──────────────────────────────────

  Future<List<PedidoModel>> listarPorUsuario(int idUsuario) async {
    debugPrint('🔍 PedidoService.listarPorUsuario — utilizador $idUsuario');

    final res = await _client
        .get(Uri.parse('$_baseUrl/usuario/$idUsuario'), headers: _headers)
        .timeout(ApiConfig.timeout);

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => PedidoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwFromResponse(res);
  }

  // ── GET /api/pedidos/status/{status} ─────────────────────────────────────

  Future<List<PedidoModel>> listarPorStatus(String status) async {
    debugPrint('🔍 PedidoService.listarPorStatus — status: $status');

    final res = await _client
        .get(Uri.parse('$_baseUrl/status/$status'), headers: _headers)
        .timeout(ApiConfig.timeout);

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => PedidoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwFromResponse(res);
  }

  // ── GET /api/pedidos/usuario/{idUsuario}/status/{status} ─────────────────

  Future<List<PedidoModel>> listarPorUsuarioEStatus(
    int idUsuario,
    String status,
  ) async {
    debugPrint(
        '🔍 PedidoService.listarPorUsuarioEStatus — utilizador $idUsuario, status $status');

    final res = await _client
        .get(
          Uri.parse('$_baseUrl/usuario/$idUsuario/status/$status'),
          headers: _headers,
        )
        .timeout(ApiConfig.timeout);

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => PedidoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwFromResponse(res);
  }

  // ── GET /api/pedidos/tipos-pagamento ─────────────────────────────────────

  Future<List<TipoPagamentoResponseDTO>> listarTiposPagamento() async {
    debugPrint('🔍 PedidoService.listarTiposPagamento');

    final res = await _client
        .get(Uri.parse('$_baseUrl/tipos-pagamento'), headers: _headers)
        .timeout(ApiConfig.timeout);

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) =>
              TipoPagamentoResponseDTO.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwFromResponse(res);
  }

  // ════════════════════════════════════════════════════════════════════════
  // RELATÓRIOS / DASHBOARD
  // ════════════════════════════════════════════════════════════════════════

  /// GET /api/pedidos/usuario/{idUsuario}/relatorio?dataInicio=2026-01-01T00:00:00
  ///
  /// Retorna: { totalPedidos: int, porDia: [ { data: String, total_pedidos: int } ] }
  Future<Map<String, dynamic>> relatorioPedidosUsuario(
    int idUsuario, {
    required DateTime dataInicio,
  }) async {
    final dataInicioStr = dataInicio.toIso8601String().split('.').first;
    debugPrint(
        '📊 PedidoService.relatorioPedidosUsuario — utilizador $idUsuario desde $dataInicioStr');

    final uri = Uri.parse('$_baseUrl/usuario/$idUsuario/relatorio')
        .replace(queryParameters: {'dataInicio': dataInicioStr});

    final res = await _client
        .get(uri, headers: _headers)
        .timeout(ApiConfig.timeout);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    _throwFromResponse(res);
  }

  /// GET /api/pedidos/usuario/{idUsuario}/dashboard?dataInicio=2026-01-01T00:00:00
  ///
  /// Retorna: { totalPedidos: int, totalVendas: double, porDia: [ { data, total_vendas } ] }
  Future<Map<String, dynamic>> dashboardUsuario(
    int idUsuario, {
    required DateTime dataInicio,
  }) async {
    final dataInicioStr = dataInicio.toIso8601String().split('.').first;
    debugPrint(
        '📊 PedidoService.dashboardUsuario — utilizador $idUsuario desde $dataInicioStr');

    final uri = Uri.parse('$_baseUrl/usuario/$idUsuario/dashboard')
        .replace(queryParameters: {'dataInicio': dataInicioStr});

    final res = await _client
        .get(uri, headers: _headers)
        .timeout(ApiConfig.timeout);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    _throwFromResponse(res);
  }

  Future<int> contarPedidosAbertos() async {
  final res = await _client
      .get(Uri.parse('$_baseUrl/count/abertos'), headers: _headers)
      .timeout(ApiConfig.timeout);

  if (res.statusCode == 200) {
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['total'] as num).toInt();
  }
  _throwFromResponse(res);
}
Future<PedidoModel> declararCredito(
  int idPedido,
  DeclararCreditoRequestModel dto,
) async {
  debugPrint('💳 PedidoService.declararCredito — pedido $idPedido');

  final res = await _client
      .post(
        Uri.parse('$_baseUrl/$idPedido/credito'),
        headers: _headers,
        body: jsonEncode(dto.toJson()),
      )
      .timeout(ApiConfig.timeout);

  return _parsePedido(res);
}

Future<List<ParcelaCreditoModel>> criarParcelas(
  int idPedido,
  CriarParcelasRequestModel dto,
) async {
  debugPrint('📆 PedidoService.criarParcelas — pedido $idPedido');

  final res = await _client
      .post(
        Uri.parse('$_baseUrl/$idPedido/credito/parcelas'),
        headers: _headers,
        body: jsonEncode(dto.toJson()),
      )
      .timeout(ApiConfig.timeout);

  if (res.statusCode >= 200 && res.statusCode < 300) {
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ParcelaCreditoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  _throwFromResponse(res);
}

Future<PagamentoCreditoModel> registarPagamentoCredito(
  int idPedido,
  RegistarPagamentoCreditoRequestModel dto,
) async {
  debugPrint('💰 PedidoService.registarPagamentoCredito — pedido $idPedido');

  final res = await _client
      .post(
        Uri.parse('$_baseUrl/$idPedido/credito/pagamentos'),
        headers: _headers,
        body: jsonEncode(dto.toJson()),
      )
      .timeout(ApiConfig.timeout);

  if (res.statusCode >= 200 && res.statusCode < 300) {
    return PagamentoCreditoModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  _throwFromResponse(res);
}

Future<List<ParcelaCreditoModel>> listarParcelas(int idPedido) async {
  debugPrint('🔍 PedidoService.listarParcelas — pedido $idPedido');

  final res = await _client
      .get(
        Uri.parse('$_baseUrl/$idPedido/credito/parcelas'),
        headers: _headers,
      )
      .timeout(ApiConfig.timeout);

  if (res.statusCode == 200) {
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ParcelaCreditoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  _throwFromResponse(res);
}

Future<List<PagamentoCreditoModel>> listarPagamentosCredito(
  int idPedido,
) async {
  debugPrint('🔍 PedidoService.listarPagamentosCredito — pedido $idPedido');

  final res = await _client
      .get(
        Uri.parse('$_baseUrl/$idPedido/credito/pagamentos'),
        headers: _headers,
      )
      .timeout(ApiConfig.timeout);

  if (res.statusCode == 200) {
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => PagamentoCreditoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  _throwFromResponse(res);
}

Future<List<PedidoModel>> listarEmDivida() async {
  debugPrint('🔍 PedidoService.listarEmDivida');

  final res = await _client
      .get(
        Uri.parse('$_baseUrl/credito/em-divida'),
        headers: _headers,
      )
      .timeout(ApiConfig.timeout);

  if (res.statusCode == 200) {
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => PedidoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  _throwFromResponse(res);
}

Future<Map<String, dynamic>> extractoCliente(int idCliente) async {
  debugPrint('📄 PedidoService.extractoCliente — cliente $idCliente');

  final res = await _client
      .get(
        Uri.parse('$_baseUrl/clientes/$idCliente/extracto'),
        headers: _headers,
      )
      .timeout(ApiConfig.timeout);

  if (res.statusCode == 200) {
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  _throwFromResponse(res);
}

// ─── Dispose ─────────────────────────────────────────────────────────────
void dispose() => _client.close();
}