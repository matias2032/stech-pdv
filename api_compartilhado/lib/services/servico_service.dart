import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/servico_model.dart';

/// Espelha ServicoService + ServicoController do Java.
///
/// Endpoints cobertos:
///   POST   /api/servicos              → criar
///   PUT    /api/servicos/{id}         → actualizar
///   PATCH  /api/servicos/{id}/toggle  → toggleAtivo
///   GET    /api/servicos/{id}         → buscarPorId
///   GET    /api/servicos              → listarTodos  (activos + inactivos)
///   GET    /api/servicos/ativos       → listarAtivos (apenas activos)
class ServicoService {
  ServicoService._();
  static final ServicoService instance = ServicoService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CRIAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST /api/servicos
  /// Espelha ServicoService.criar()
  /// Cria um novo serviço no catálogo. Activo por omissão.
  Future<ServicoModel> criar(ServicoRequestModel dto) async {
    final url = Uri.parse(ApiConfig.servicosUrl);
    debugPrint('POST $url');

    final response = await http
        .post(url, headers: _headers, body: jsonEncode(dto.toJson()))
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 201, 'criar serviço');
    return ServicoModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTUALIZAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// PUT /api/servicos/{id}
  /// Espelha ServicoService.actualizar()
  /// Actualiza nome, descrição, preço e unidade.
  /// Não altera o estado ativo — use toggleAtivo() para isso.
  Future<ServicoModel> actualizar(int id, ServicoRequestModel dto) async {
    final url = Uri.parse('${ApiConfig.servicosUrl}/$id');
    debugPrint('PUT $url');

    final response = await http
        .put(url, headers: _headers, body: jsonEncode(dto.toJson()))
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'actualizar serviço');
    return ServicoModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOGGLE ACTIVO / INACTIVO
  // ═══════════════════════════════════════════════════════════════════════════

  /// PATCH /api/servicos/{id}/toggle
  /// Espelha ServicoService.toggleAtivo()
  /// Inverte o estado ativo (true → false ou false → true).
  /// Nunca elimina o registo — preserva histórico de pedidos.
  Future<ServicoModel> toggleAtivo(int id) async {
    final url = Uri.parse('${ApiConfig.servicosUrl}/$id/toggle');
    debugPrint('PATCH $url');

    final response = await http
        .patch(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'toggleAtivo serviço');
    return ServicoModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSULTAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET /api/servicos/{id}
  /// Espelha ServicoService.buscarPorId()
  Future<ServicoModel> buscarPorId(int id) async {
    final url = Uri.parse('${ApiConfig.servicosUrl}/$id');
    debugPrint('GET $url');

    final response = await http
        .get(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'buscar serviço por id');
    return ServicoModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// GET /api/servicos
  /// Espelha ServicoService.listarTodos()
  /// Devolve activos e inactivos ordenados por nome.
  /// Destinado ao painel de gestão/administração.
  Future<List<ServicoModel>> listarTodos() async {
    final url = Uri.parse(ApiConfig.servicosUrl);
    debugPrint('GET $url');

    final response = await http
        .get(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'listar todos os serviços');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ServicoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/servicos/ativos
  /// Espelha ServicoService.listarAtivos()
  /// Devolve apenas os serviços activos.
  /// Destinado ao ecrã de criação/edição de pedido no frontend.
  Future<List<ServicoModel>> listarAtivos() async {
    final url = Uri.parse('${ApiConfig.servicosUrl}/ativos');
    debugPrint('GET $url');

    final response = await http
        .get(url, headers: _headers)
        .timeout(ApiConfig.timeout);

    _assertStatus(response, 200, 'listar serviços ativos');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ServicoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, String> get _headers => ApiConfig.defaultHeaders;

  void _assertStatus(http.Response response, int expected, String operacao) {
    if (response.statusCode != expected) {
      debugPrint(
          '❌ $operacao — esperado $expected, recebido ${response.statusCode}');
      debugPrint('   body: ${response.body}');
      throw HttpException(
        'Erro em "$operacao": HTTP ${response.statusCode} — ${response.body}',
      );
    }
  }
}