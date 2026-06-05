// lib/services/categoria_service.dart  (dentro de api_compartilhado)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_config.dart';
import 'package:api_compartilhado/models/categoria_model.dart';

class CategoriaServiceException implements Exception {
  final String message;
  const CategoriaServiceException(this.message);
  @override
  String toString() => 'CategoriaServiceException: $message';
}

class CategoriaService {
  CategoriaService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<CategoriaModel>> listarCategorias() async {
    final response = await _client
        .get(Uri.parse(ApiConfig.categoriasUrl), headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map((j) => CategoriaModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw CategoriaServiceException('Erro ao carregar categorias: ${response.statusCode}');
  }

  Future<CategoriaModel> buscarCategoriaPorId(int id) async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.categoriasUrl}/$id'), headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      return CategoriaModel.fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    throw CategoriaServiceException('Categoria não encontrada: ${response.statusCode}');
  }

  Future<CategoriaModel> criarCategoria(CategoriaRequestDTO dto) async {
    final response = await _client
        .post(
          Uri.parse(ApiConfig.categoriasUrl),
          headers: ApiConfig.defaultHeaders,
          body: json.encode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return CategoriaModel.fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    throw CategoriaServiceException('Erro ao criar categoria: ${response.statusCode}');
  }

  Future<CategoriaModel> atualizarCategoria(int id, CategoriaRequestDTO dto) async {
    final response = await _client
        .put(
          Uri.parse('${ApiConfig.categoriasUrl}/$id'),
          headers: ApiConfig.defaultHeaders,
          body: json.encode(dto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      return CategoriaModel.fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    throw CategoriaServiceException('Erro ao atualizar categoria: ${response.statusCode}');
  }

  Future<void> deletarCategoria(int id) async {
    final response = await _client
        .delete(Uri.parse('${ApiConfig.categoriasUrl}/$id'), headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw CategoriaServiceException('Erro ao deletar categoria: ${response.statusCode}');
    }
  }

  Future<void> associarMarca(int idCategoria, int idMarca) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.categoriasUrl}/$idCategoria/marcas/$idMarca'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode != 200) {
      throw CategoriaServiceException('Erro ao associar marca: ${response.statusCode}');
    }
  }

  Future<void> desassociarMarca(int idCategoria, int idMarca) async {
    final response = await _client
        .delete(
          Uri.parse('${ApiConfig.categoriasUrl}/$idCategoria/marcas/$idMarca'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw CategoriaServiceException('Erro ao desassociar marca: ${response.statusCode}');
    }
  }
}