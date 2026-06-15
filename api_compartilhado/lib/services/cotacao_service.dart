// lib/services/cotacao_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/cotacao_model.dart';
import '../models/pedido_model.dart';

// ─── Excepções de domínio ────────────────────────────────────────────────────
// Espelho das excepções de com.stechengenharia.pdv_backend.cotacao.exception

class CotacaoNaoEncontradaException implements Exception {
  final int idCotacao;
  CotacaoNaoEncontradaException(this.idCotacao);

  @override
  String toString() => 'Cotação $idCotacao não encontrada.';
}

class CotacaoNaoEditavelException implements Exception {
  final String mensagem;
  CotacaoNaoEditavelException(this.mensagem);

  @override
  String toString() => mensagem;
}

class CotacaoSemItensException implements Exception {
  final String referencia;
  CotacaoSemItensException(this.referencia);

  @override
  String toString() =>
      'A cotação $referencia não tem itens e não pode ser convertida.';
}

class ItemCotacaoNaoEncontradoException implements Exception {
  final int idItem;
  final int idCotacao;
  ItemCotacaoNaoEncontradoException(this.idItem, this.idCotacao);

  @override
  String toString() => 'Item $idItem não pertence à cotação $idCotacao.';
}

// ════════════════════════════════════════════════════════════════════════════
// CotacaoService
// Espelho completo de CotacaoService.java / CotacaoController.java
// ════════════════════════════════════════════════════════════════════════════

class CotacaoService {
  // Reutiliza o cliente HTTP entre chamadas para melhor performance
  final http.Client _client;

  CotacaoService({http.Client? client}) : _client = client ?? http.Client();

  // ── headers padrão ────────────────────────────────────────────────────────

  Map<String, String> get _headers => ApiConfig.defaultHeaders;

  // ── helper: URL base das cotações ────────────────────────────────────────
  // NOTA: requer adicionar `cotacoesUrl` em ApiConfig (ex.: '$baseUrl/api/cotacoes')

  String get _baseUrl => ApiConfig.cotacoesUrl;

  // ── helper: lança excepção de domínio a partir da resposta HTTP ───────────

  Never _throwFromResponse(http.Response res, {int idCotacao = 0, int idItem = 0}) {
    final body = res.body;
    debugPrint('❌ CotacaoService — ${res.statusCode}: $body');

    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final msg = (json['message'] ?? json['error'] ?? body).toString();

      if (res.statusCode == 404) {
        if (idItem != 0) {
          throw ItemCotacaoNaoEncontradoException(idItem, idCotacao);
        }
        throw CotacaoNaoEncontradaException(idCotacao);
      }
      if (res.statusCode == 409 || msg.toLowerCase().contains('não pode ser') ||
          msg.toLowerCase().contains('não editável') ||
          msg.toLowerCase().contains('está') ) {
        throw CotacaoNaoEditavelException(msg);
      }
      throw Exception('Erro ${res.statusCode}: $msg');
    } catch (e) {
      if (e is CotacaoNaoEncontradaException ||
          e is CotacaoNaoEditavelException ||
          e is CotacaoSemItensException ||
          e is ItemCotacaoNaoEncontradoException) rethrow;
      throw Exception('Erro ${res.statusCode}: $body');
    }
  }

  // ── helper: parse de CotacaoModel ────────────────────────────────────────

  CotacaoModel _parseCotacao(http.Response res, {int idCotacao = 0, int idItem = 0}) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return CotacaoModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    _throwFromResponse(res, idCotacao: idCotacao, idItem: idItem);
  }

  // ════════════════════════════════════════════════════════════════════════
  // COTAÇÃO — CRUD base
  // ════════════════════════════════════════════════════════════════════════

  // ── a) CRIAR COTAÇÃO ───────────────────────────────────────────────────
  // POST /api/cotacoes

  Future<CotacaoModel> criarCotacao(CriarCotacaoRequestModel dto) async {
    debugPrint('📋 CotacaoService.criarCotacao — utilizador ${dto.idUsuario}');

    final res = await _client
        .post(
          Uri.parse(_baseUrl),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parseCotacao(res);
  }

  // ── b) LISTAR COTAÇÕES ─────────────────────────────────────────────────
  // GET /api/cotacoes  (?status= | ?idCliente= | ?idUsuario=)

  Future<List<CotacaoModel>> listarTodas() async {
    debugPrint('🔍 CotacaoService.listarTodas');

    final res = await _client
        .get(Uri.parse(_baseUrl), headers: _headers)
        .timeout(ApiConfig.timeout);

    return _parseLista(res);
  }

  Future<List<CotacaoModel>> listarPorStatus(String status) async {
    debugPrint('🔍 CotacaoService.listarPorStatus — $status');

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {'status': status});
    final res = await _client.get(uri, headers: _headers).timeout(ApiConfig.timeout);

    return _parseLista(res);
  }

  Future<List<CotacaoModel>> listarPorCliente(int idCliente) async {
    debugPrint('🔍 CotacaoService.listarPorCliente — $idCliente');

    final uri = Uri.parse(_baseUrl)
        .replace(queryParameters: {'idCliente': '$idCliente'});
    final res = await _client.get(uri, headers: _headers).timeout(ApiConfig.timeout);

    return _parseLista(res);
  }

  Future<List<CotacaoModel>> listarPorUsuario(int idUsuario) async {
    debugPrint('🔍 CotacaoService.listarPorUsuario — $idUsuario');

    final uri = Uri.parse(_baseUrl)
        .replace(queryParameters: {'idUsuario': '$idUsuario'});
    final res = await _client.get(uri, headers: _headers).timeout(ApiConfig.timeout);

    return _parseLista(res);
  }

  List<CotacaoModel> _parseLista(http.Response res) {
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => CotacaoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwFromResponse(res);
  }

  // ── c) VISUALIZAR COTAÇÃO ──────────────────────────────────────────────
  // GET /api/cotacoes/{idCotacao}

  Future<CotacaoModel> buscarPorId(int idCotacao) async {
    debugPrint('🔍 CotacaoService.buscarPorId — $idCotacao');

    final res = await _client
        .get(Uri.parse('$_baseUrl/$idCotacao'), headers: _headers)
        .timeout(ApiConfig.timeout);

    return _parseCotacao(res, idCotacao: idCotacao);
  }

  // ── d) ACTUALIZAR COTAÇÃO ──────────────────────────────────────────────
  // PUT /api/cotacoes/{idCotacao}

  Future<CotacaoModel> atualizarCotacao(
    int idCotacao,
    AtualizarCotacaoRequestModel dto,
  ) async {
    debugPrint('✏️  CotacaoService.atualizarCotacao — $idCotacao');

    final res = await _client
        .put(
          Uri.parse('$_baseUrl/$idCotacao'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parseCotacao(res, idCotacao: idCotacao);
  }

  // ── e) EXCLUIR (soft delete) ───────────────────────────────────────────
  // DELETE /api/cotacoes/{idCotacao}  → 204 No Content

  Future<void> excluirCotacao(int idCotacao) async {
    debugPrint('🗑️  CotacaoService.excluirCotacao — $idCotacao');

    final res = await _client
        .delete(Uri.parse('$_baseUrl/$idCotacao'), headers: _headers)
        .timeout(ApiConfig.timeout);

    if (res.statusCode != 204 && res.statusCode != 200) {
      _throwFromResponse(res, idCotacao: idCotacao);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ITENS DE PRODUTO
  // ════════════════════════════════════════════════════════════════════════

  // ── f) ADICIONAR ITEM DE PRODUTO ───────────────────────────────────────
  // POST /api/cotacoes/{idCotacao}/produtos

  Future<CotacaoModel> adicionarProduto(
    int idCotacao,
    AdicionarProdutoCotacaoRequestModel dto,
  ) async {
    debugPrint(
        '📋 CotacaoService.adicionarProduto — cotação $idCotacao, produto ${dto.idProduto}');

    final res = await _client
        .post(
          Uri.parse('$_baseUrl/$idCotacao/produtos'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parseCotacao(res, idCotacao: idCotacao);
  }

  // ── h) ACTUALIZAR ITEM DE PRODUTO ──────────────────────────────────────
  // PUT /api/cotacoes/{idCotacao}/produtos/{idItem}

  Future<CotacaoModel> atualizarItemProduto(
    int idCotacao,
    int idItem,
    AtualizarItemCotacaoRequestModel dto,
  ) async {
    debugPrint(
        '✏️  CotacaoService.atualizarItemProduto — cotação $idCotacao, item $idItem');

    final res = await _client
        .put(
          Uri.parse('$_baseUrl/$idCotacao/produtos/$idItem'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parseCotacao(res, idCotacao: idCotacao, idItem: idItem);
  }

  // ── j) REMOVER ITEM DE PRODUTO ─────────────────────────────────────────
  // DELETE /api/cotacoes/{idCotacao}/produtos/{idItem}

  Future<CotacaoModel> removerItemProduto(int idCotacao, int idItem) async {
    debugPrint(
        '🗑️  CotacaoService.removerItemProduto — cotação $idCotacao, item $idItem');

    final res = await _client
        .delete(
          Uri.parse('$_baseUrl/$idCotacao/produtos/$idItem'),
          headers: _headers,
        )
        .timeout(ApiConfig.timeout);

    return _parseCotacao(res, idCotacao: idCotacao, idItem: idItem);
  }

  // ════════════════════════════════════════════════════════════════════════
  // ITENS DE SERVIÇO
  // ════════════════════════════════════════════════════════════════════════

  // ── g) ADICIONAR ITEM DE SERVIÇO ───────────────────────────────────────
  // POST /api/cotacoes/{idCotacao}/servicos

  Future<CotacaoModel> adicionarServico(
    int idCotacao,
    AdicionarServicoCotacaoRequestModel dto,
  ) async {
    debugPrint(
        '📋 CotacaoService.adicionarServico — cotação $idCotacao, serviço ${dto.idServico}');

    final res = await _client
        .post(
          Uri.parse('$_baseUrl/$idCotacao/servicos'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parseCotacao(res, idCotacao: idCotacao);
  }

  // ── i) ACTUALIZAR ITEM DE SERVIÇO ──────────────────────────────────────
  // PUT /api/cotacoes/{idCotacao}/servicos/{idItem}

  Future<CotacaoModel> atualizarItemServico(
    int idCotacao,
    int idItem,
    AtualizarItemCotacaoRequestModel dto,
  ) async {
    debugPrint(
        '✏️  CotacaoService.atualizarItemServico — cotação $idCotacao, item $idItem');

    final res = await _client
        .put(
          Uri.parse('$_baseUrl/$idCotacao/servicos/$idItem'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    return _parseCotacao(res, idCotacao: idCotacao, idItem: idItem);
  }

  // ── k) REMOVER ITEM DE SERVIÇO ─────────────────────────────────────────
  // DELETE /api/cotacoes/{idCotacao}/servicos/{idItem}

  Future<CotacaoModel> removerItemServico(int idCotacao, int idItem) async {
    debugPrint(
        '🗑️  CotacaoService.removerItemServico — cotação $idCotacao, item $idItem');

    final res = await _client
        .delete(
          Uri.parse('$_baseUrl/$idCotacao/servicos/$idItem'),
          headers: _headers,
        )
        .timeout(ApiConfig.timeout);

    return _parseCotacao(res, idCotacao: idCotacao, idItem: idItem);
  }

  // ════════════════════════════════════════════════════════════════════════
  // CONVERSÃO
  // ════════════════════════════════════════════════════════════════════════

  // ── l) CONVERTER COTAÇÃO EM PEDIDO ─────────────────────────────────────
  // POST /api/cotacoes/{idCotacao}/converter-em-pedido → PedidoResponseDTO

  Future<PedidoModel> converterEmPedido(
    int idCotacao,
    ConverterCotacaoEmPedidoRequestModel dto,
  ) async {
    debugPrint('🔄 CotacaoService.converterEmPedido — cotação $idCotacao');

    final res = await _client
        .post(
          Uri.parse('$_baseUrl/$idCotacao/converter-em-pedido'),
          headers: _headers,
          body: jsonEncode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return PedidoModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    _throwFromResponse(res, idCotacao: idCotacao);
  }

  // ─── Dispose ─────────────────────────────────────────────────────────────

  void dispose() => _client.close();
}