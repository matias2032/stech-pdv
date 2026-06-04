// lib/services/marca_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/marca_model.dart';
import 'package:api_compartilhado/api_config.dart';

class MarcaService {
  // ===== LISTAR TODAS AS MARCAS =====
  Future<List<Marca>> listarMarcas() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.marcasUrl),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Marca.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar marcas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no listarMarcas: $e');
      rethrow;
    }
  }

// ===== LISTAR MARCAS COM CATEGORIAS =====
Future<List<Marca>> listarMarcasComCategorias() async {
  try {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.marcasUrl}/com-categorias'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Marca.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar marcas: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erro no listarMarcasComCategorias: $e');
    rethrow;
  }
}

  // ===== BUSCAR MARCA POR ID =====
  Future<Marca> buscarMarcaPorId(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.marcasUrl}/$id'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Marca.fromJson(json.decode(response.body));
      } else {
        throw Exception('Marca não encontrada: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no buscarMarcaPorId: $e');
      rethrow;
    }
  }

  // ===== CRIAR MARCA =====
  Future<Marca> criarMarca(Marca marca) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.marcasUrl),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(marca.toJsonCreate()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Marca criada com sucesso');
        return Marca.fromJson(json.decode(response.body));
      } else {
        throw Exception('Erro ao criar marca: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no criarMarca: $e');
      rethrow;
    }
  }

  // ===== ATUALIZAR MARCA =====
  Future<Marca> atualizarMarca(int id, Marca marca) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.marcasUrl}/$id'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(marca.toJsonCreate()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        print('✅ Marca atualizada com sucesso');
        return Marca.fromJson(json.decode(response.body));
      } else {
        throw Exception('Erro ao atualizar marca: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no atualizarMarca: $e');
      rethrow;
    }
  }

  // ===== DELETAR MARCA =====
  Future<void> deletarMarca(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.marcasUrl}/$id'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Marca deletada com sucesso');
      } else {
        throw Exception('Erro ao deletar marca: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no deletarMarca: $e');
      rethrow;
    }
  }

  // ===== LISTAR CATEGORIAS DA MARCA =====
  // Usa o endpoint de CATEGORIA (categoria_marca)
  Future<List<int>> listarCategoriasDaMarca(int idMarca) async {
    try {
      // Busca via endpoint de categoria que já existe
      final response = await http
          .get(
            Uri.parse('${ApiConfig.categoriasUrl}/marca/$idMarca'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<int>();
      } else if (response.statusCode == 404) {
        // Endpoint não existe, vamos buscar todas e filtrar
        // Ou retornar lista vazia
        return [];
      } else {
        throw Exception('Erro ao carregar categorias: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no listarCategoriasDaMarca: $e');
      // Se der erro, retorna lista vazia
      return [];
    }
  }

  // ===== ASSOCIAR CATEGORIA À MARCA =====
  // Usa o endpoint de CATEGORIA (POST /api/categorias/{idCategoria}/marcas/{idMarca})
  Future<void> associarCategoria(int idMarca, int idCategoria) async {
    try {
      final response = await http
          .post(
            Uri.parse(
                '${ApiConfig.categoriasUrl}/$idCategoria/marcas/$idMarca'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        print('✅ Categoria $idCategoria associada à marca $idMarca');
      } else {
        throw Exception('Erro ao associar categoria: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no associarCategoria: $e');
      rethrow;
    }
  }

  // ===== DESASSOCIAR CATEGORIA DA MARCA =====
  // Usa o endpoint de CATEGORIA (DELETE /api/categorias/{idCategoria}/marcas/{idMarca})
  Future<void> desassociarCategoria(int idMarca, int idCategoria) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
                '${ApiConfig.categoriasUrl}/$idCategoria/marcas/$idMarca'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Categoria $idCategoria desassociada da marca $idMarca');
      } else {
        throw Exception(
            'Erro ao desassociar categoria: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no desassociarCategoria: $e');
      rethrow;
    }
  }
}