import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_compartilhado.dart';
import '../models/fornecedor_model.dart';

class FornecedorService {
  final http.Client _client;

  FornecedorService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  // ── GET /api/fornecedores ─────────────────────────────────────────

  Future<List<FornecedorModel>> listar() async {
    final uri = Uri.parse(ApiConfig.fornecedoresUrl);

    final response = await _client
        .get(uri, headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    _validarResposta(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! List) {
      throw Exception('Resposta inválida ao listar fornecedores.');
    }

    return data
        .map((item) => FornecedorModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ── GET /api/fornecedores?q=texto ─────────────────────────────────

  Future<List<FornecedorModel>> pesquisar(String termo) async {
    final q = termo.trim();

    if (q.isEmpty) {
      return listar();
    }

    final uri = Uri.parse(ApiConfig.fornecedoresUrl).replace(
      queryParameters: {
        'q': q,
      },
    );

    final response = await _client
        .get(uri, headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    _validarResposta(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! List) {
      throw Exception('Resposta inválida ao pesquisar fornecedores.');
    }

    return data
        .map((item) => FornecedorModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ── GET /api/fornecedores/{id} ────────────────────────────────────

  Future<FornecedorModel> buscarPorId(int id) async {
    final uri = Uri.parse('${ApiConfig.fornecedoresUrl}/$id');

    final response = await _client
        .get(uri, headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    _validarResposta(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao buscar fornecedor.');
    }

    return FornecedorModel.fromJson(data);
  }

  // ── POST /api/fornecedores ────────────────────────────────────────

  Future<FornecedorModel> criar(FornecedorModel fornecedor) async {
    _validarFornecedor(fornecedor);

    final uri = Uri.parse(ApiConfig.fornecedoresUrl);

    final response = await _client
        .post(
          uri,
          headers: ApiConfig.defaultHeaders,
          body: jsonEncode(fornecedor.toJson()),
        )
        .timeout(ApiConfig.timeout);

    _validarResposta(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao criar fornecedor.');
    }

    return FornecedorModel.fromJson(data);
  }

  // ── PUT /api/fornecedores/{id} ────────────────────────────────────

  Future<FornecedorModel> editar({
    required int id,
    required FornecedorModel fornecedor,
  }) async {
    _validarFornecedor(fornecedor);

    final uri = Uri.parse('${ApiConfig.fornecedoresUrl}/$id');

    final response = await _client
        .put(
          uri,
          headers: ApiConfig.defaultHeaders,
          body: jsonEncode(fornecedor.toJson()),
        )
        .timeout(ApiConfig.timeout);

    _validarResposta(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao editar fornecedor.');
    }

    return FornecedorModel.fromJson(data);
  }

  // ── DELETE /api/fornecedores/{id} ─────────────────────────────────

  Future<void> excluir(int id) async {
    final uri = Uri.parse('${ApiConfig.fornecedoresUrl}/$id');

    final response = await _client
        .delete(uri, headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    _validarResposta(response, aceitarSemConteudo: true);
  }

  // ── Validações locais ─────────────────────────────────────────────

  void _validarFornecedor(FornecedorModel fornecedor) {
    if (!fornecedor.contactoValido) {
      throw Exception('Contacto é obrigatório.');
    }
  }

  void _validarResposta(
    http.Response response, {
    bool aceitarSemConteudo = false,
  }) {
    if (aceitarSemConteudo && response.statusCode == 204) {
      return;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String mensagem = 'Erro HTTP ${response.statusCode}';

    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));

      if (body is Map) {
        mensagem = body['message']?.toString() ??
            body['erro']?.toString() ??
            body['error']?.toString() ??
            mensagem;
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        mensagem = response.body;
      }
    }

    throw Exception(mensagem);
  }
}
