// lib/services/marca_service.dart  (dentro de api_compartilhado)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_config.dart';
import 'package:api_compartilhado/models/marca_model.dart';

class MarcaServiceException implements Exception {
  final String message;
  const MarcaServiceException(this.message);
  @override
  String toString() => 'MarcaServiceException: $message';
}

class MarcaService {
  MarcaService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // ── Listar todas ──────────────────────────────────────────────────

  Future<List<MarcaModel>> listarMarcas() async {
    final response = await _client
        .get(Uri.parse(ApiConfig.marcasUrl), headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map((j) => MarcaModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw MarcaServiceException('Erro ao carregar marcas: ${response.statusCode}');
  }

  // ── Listar com categorias ─────────────────────────────────────────

  Future<List<MarcaModel>> listarMarcasComCategorias() async {
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.marcasUrl}/com-categorias'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map((j) => MarcaModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw MarcaServiceException('Erro ao carregar marcas com categorias: ${response.statusCode}');
  }

  // ── Buscar por ID ─────────────────────────────────────────────────

  Future<MarcaModel> buscarMarcaPorId(int id) async {
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.marcasUrl}/$id'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      return MarcaModel.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw MarcaServiceException('Marca não encontrada: ${response.statusCode}');
  }

  // ── Criar ─────────────────────────────────────────────────────────

  Future<MarcaModel> criarMarca(MarcaRequestDTO dto) async {
    final response = await _client
        .post(
          Uri.parse(ApiConfig.marcasUrl),
          headers: ApiConfig.defaultHeaders,
          body: json.encode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return MarcaModel.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw MarcaServiceException('Erro ao criar marca: ${response.statusCode}');
  }

  // ── Atualizar ─────────────────────────────────────────────────────

  Future<MarcaModel> atualizarMarca(int id, MarcaRequestDTO dto) async {
    final response = await _client
        .put(
          Uri.parse('${ApiConfig.marcasUrl}/$id'),
          headers: ApiConfig.defaultHeaders,
          body: json.encode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      return MarcaModel.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw MarcaServiceException('Erro ao atualizar marca: ${response.statusCode}');
  }

  // ── Deletar ───────────────────────────────────────────────────────

  Future<void> deletarMarca(int id) async {
    final response = await _client
        .delete(
          Uri.parse('${ApiConfig.marcasUrl}/$id'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw MarcaServiceException('Erro ao deletar marca: ${response.statusCode}');
    }
  }

  // ── Associar categoria ────────────────────────────────────────────

  Future<void> associarCategoria(int idMarca, int idCategoria) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.categoriasUrl}/$idCategoria/marcas/$idMarca'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode != 200) {
      throw MarcaServiceException('Erro ao associar categoria: ${response.statusCode}');
    }
  }

  // ── Desassociar categoria ─────────────────────────────────────────

  Future<void> desassociarCategoria(int idMarca, int idCategoria) async {
    final response = await _client
        .delete(
          Uri.parse('${ApiConfig.categoriasUrl}/$idCategoria/marcas/$idMarca'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw MarcaServiceException('Erro ao desassociar categoria: ${response.statusCode}');
    }
  }
}