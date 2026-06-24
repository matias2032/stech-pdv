import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_compartilhado.dart';

class DespesaService {
  final http.Client _client;

  DespesaService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  // ── GET /api/despesas ─────────────────────────────────────────────

  Future<List<DespesaModel>> listar() async {
    final uri = Uri.parse(ApiConfig.despesasUrl);

    final response = await _client
        .get(uri, headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    _validarResposta(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! List) {
      throw Exception('Resposta inválida ao listar despesas.');
    }

    return data
        .map((item) => DespesaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

// ── GET /api/despesas/excluidas ───────────────────────────────────

Future<List<DespesaModel>> listarExcluidas() async {
  final uri = Uri.parse('${ApiConfig.despesasUrl}/excluidas');

  final response = await _client
      .get(uri, headers: ApiConfig.defaultHeaders)
      .timeout(ApiConfig.timeout);

  _validarResposta(response);

  final data = jsonDecode(utf8.decode(response.bodyBytes));

  if (data is! List) {
    throw Exception('Resposta inválida ao listar despesas excluídas.');
  }

  return data
      .map((item) => DespesaModel.fromJson(item as Map<String, dynamic>))
      .toList();
}
  // ── GET /api/despesas/{id} ────────────────────────────────────────

  Future<DespesaModel> buscarPorId(int id) async {
    final uri = Uri.parse('${ApiConfig.despesasUrl}/$id');

    final response = await _client
        .get(uri, headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    _validarResposta(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao buscar despesa.');
    }

    return DespesaModel.fromJson(data);
  }

  // ── GET /api/despesas/fornecedor/{idFornecedor} ──────────────────

  Future<List<DespesaModel>> listarPorFornecedor(int idFornecedor) async {
    final uri = Uri.parse('${ApiConfig.despesasUrl}/fornecedor/$idFornecedor');

    final response = await _client
        .get(uri, headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    _validarResposta(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! List) {
      throw Exception('Resposta inválida ao listar despesas por fornecedor.');
    }

    return data
        .map((item) => DespesaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ── GET /api/despesas/periodo ─────────────────────────────────────

  Future<List<DespesaModel>> listarPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final uri = Uri.parse(ApiConfig.despesasUrl).replace(
      path: Uri.parse(ApiConfig.despesasUrl).path + '/periodo',
      queryParameters: {
        'inicio': inicio.toUtc().toIso8601String(),
        'fim': fim.toUtc().toIso8601String(),
      },
    );

    final response = await _client
        .get(uri, headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    _validarResposta(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! List) {
      throw Exception('Resposta inválida ao listar despesas por período.');
    }

    return data
        .map((item) => DespesaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ── POST /api/despesas ────────────────────────────────────────────

  Future<DespesaModel> criar(DespesaModel despesa) async {
    _validarDespesa(despesa);

    final uri = Uri.parse(ApiConfig.despesasUrl);

    final response = await _client
        .post(
          uri,
          headers: ApiConfig.defaultHeaders,
          body: jsonEncode(despesa.toJson()),
        )
        .timeout(ApiConfig.timeout);

    _validarResposta(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao criar despesa.');
    }

    return DespesaModel.fromJson(data);
  }

  // ── PUT /api/despesas/{id} ────────────────────────────────────────

  Future<DespesaModel> editar({
    required int id,
    required DespesaModel despesa,
  }) async {
    _validarDespesa(despesa);

    final uri = Uri.parse('${ApiConfig.despesasUrl}/$id');

    final response = await _client
        .put(
          uri,
          headers: ApiConfig.defaultHeaders,
          body: jsonEncode(despesa.toJson()),
        )
        .timeout(ApiConfig.timeout);

    _validarResposta(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao editar despesa.');
    }

    return DespesaModel.fromJson(data);
  }

  // ── DELETE /api/despesas/{id} ─────────────────────────────────────

  Future<void> excluir(int id) async {
    final uri = Uri.parse('${ApiConfig.despesasUrl}/$id');

    final response = await _client
        .delete(uri, headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    _validarResposta(response, aceitarSemConteudo: true);
  }

  // ── PATCH /api/despesas/{id}/excluir ───────────────────────────────

Future<void> excluirComMotivo({
  required int id,
  required String? motivoExclusao,
}) async {
  final uri = Uri.parse('${ApiConfig.despesasUrl}/$id/excluir');

  final response = await _client
      .patch(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'motivoExclusao': motivoExclusao?.trim(),
        }),
      )
      .timeout(ApiConfig.timeout);

  _validarResposta(response, aceitarSemConteudo: true);
}

  // ── Helpers ───────────────────────────────────────────────────────

void _validarDespesa(DespesaModel despesa) {
  if (!despesa.descricaoValida) {
    throw Exception('A descrição da despesa é obrigatória.');
  }

  if (!despesa.valorValido) {
    throw Exception('O valor gasto deve ser maior que zero.');
  }

  if (!despesa.tipoValido) {
    throw Exception('O tipo de despesa é obrigatório.');
  }
}

  void _validarResposta(
    http.Response response, {
    bool aceitarSemConteudo = false,
  }) {
    if (aceitarSemConteudo && response.statusCode == 204) return;

    if (response.statusCode >= 200 && response.statusCode < 300) return;

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

  Future<List<TipoDespesaModel>> listarTiposDespesa() async {
  final uri = Uri.parse('${ApiConfig.despesasUrl}/tipos');

  final response = await _client
      .get(uri, headers: ApiConfig.defaultHeaders)
      .timeout(ApiConfig.timeout);

  _validarResposta(response);

  final data = jsonDecode(utf8.decode(response.bodyBytes));

  if (data is! List) {
    throw Exception('Resposta inválida ao listar tipos de despesa.');
  }

  return data
      .map((item) => TipoDespesaModel.fromJson(item as Map<String, dynamic>))
      .toList();
}


}