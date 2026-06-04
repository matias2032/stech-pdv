// lib/services/categoria_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_config.dart';
import '../models/categoria_model.dart';

class CategoriaService {
  // ===== LISTAR TODAS AS CATEGORIAS =====
  Future<List<Categoria>> listarCategorias() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.categoriasUrl),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Categoria.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar categorias: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no listarCategorias: $e');
      rethrow;
    }
  }

  // ===== BUSCAR CATEGORIA POR ID =====
  Future<Categoria> buscarCategoriaPorId(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.categoriasUrl}/$id'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Categoria.fromJson(json.decode(response.body));
      } else {
        throw Exception('Categoria não encontrada: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no buscarCategoriaPorId: $e');
      rethrow;
    }
  }

  // ===== CRIAR CATEGORIA =====
  Future<Categoria> criarCategoria(Categoria categoria) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.categoriasUrl),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(categoria.toJsonCreate()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Categoria criada com sucesso');
        return Categoria.fromJson(json.decode(response.body));
      } else {
        throw Exception('Erro ao criar categoria: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no criarCategoria: $e');
      rethrow;
    }
  }

  // ===== ATUALIZAR CATEGORIA =====
  Future<Categoria> atualizarCategoria(int id, Categoria categoria) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.categoriasUrl}/$id'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(categoria.toJsonCreate()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        print('✅ Categoria atualizada com sucesso');
        return Categoria.fromJson(json.decode(response.body));
      } else {
        throw Exception('Erro ao atualizar categoria: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no atualizarCategoria: $e');
      rethrow;
    }
  }

  // ===== DELETAR CATEGORIA =====
  Future<void> deletarCategoria(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.categoriasUrl}/$id'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Categoria deletada com sucesso');
      } else {
        throw Exception('Erro ao deletar categoria: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no deletarCategoria: $e');
      rethrow;
    }
  }

  // ===== LISTAR MARCAS DA CATEGORIA =====
  Future<List<int>> listarMarcasDaCategoria(int idCategoria) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.categoriasUrl}/$idCategoria/marcas'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<int>();
      } else {
        throw Exception('Erro ao carregar marcas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no listarMarcasDaCategoria: $e');
      rethrow;
    }
  }

  // ===== ASSOCIAR MARCA À CATEGORIA =====
  Future<void> associarMarca(int idCategoria, int idMarca) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.categoriasUrl}/$idCategoria/marcas/$idMarca'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        print('✅ Marca $idMarca associada à categoria $idCategoria');
      } else {
        throw Exception('Erro ao associar marca: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no associarMarca: $e');
      rethrow;
    }
  }

  // ===== DESASSOCIAR MARCA DA CATEGORIA =====
  Future<void> desassociarMarca(int idCategoria, int idMarca) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.categoriasUrl}/$idCategoria/marcas/$idMarca'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Marca $idMarca desassociada da categoria $idCategoria');
      } else {
        throw Exception('Erro ao desassociar marca: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no desassociarMarca: $e');
      rethrow;
    }
  }
}