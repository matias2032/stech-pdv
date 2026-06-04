import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_config.dart';
import 'package:api_compartilhado/models/cliente_model.dart';

/// Todas as excepções lançadas pelo service são do tipo [ClienteServiceException],
/// com uma mensagem legível para mostrar directamente na UI.
class ClienteServiceException implements Exception {
  final String mensagem;
  const ClienteServiceException(this.mensagem);

  @override
  String toString() => mensagem;
}

class ClienteService {
  ClienteService({required this.baseUrl, required this.httpClient});

  final String      baseUrl;
  final http.Client httpClient;

  // ── Cabeçalhos padrão ─────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
      };

  // ─────────────────────────────────────────────────────────────────
  // LISTAR TODOS
  // GET /api/clientes
  // ─────────────────────────────────────────────────────────────────

  Future<List<ClienteModel>> listarTodos() async {
    final uri = Uri.parse('$baseUrl/api/clientes');
    try {
      final response = await httpClient.get(uri, headers: _headers);
      _assertOk(response, 'Erro ao listar clientes');
      final lista = jsonDecode(response.body) as List<dynamic>;
      return lista
          .map((e) => ClienteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ClienteServiceException {
      rethrow;
    } catch (e) {
      throw ClienteServiceException('Falha de ligação ao listar clientes: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // FILTRAR POR PERFIL
  // GET /api/clientes?perfil={idPerfil}
  // ─────────────────────────────────────────────────────────────────

  Future<List<ClienteModel>> listarPorPerfil(int idPerfil) async {
    final uri = Uri.parse('$baseUrl/api/clientes')
        .replace(queryParameters: {'perfil': idPerfil.toString()});
    try {
      final response = await httpClient.get(uri, headers: _headers);
      _assertOk(response, 'Erro ao filtrar clientes por perfil');
      final lista = jsonDecode(response.body) as List<dynamic>;
      return lista
          .map((e) => ClienteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ClienteServiceException {
      rethrow;
    } catch (e) {
      throw ClienteServiceException('Falha de ligação ao filtrar clientes: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PESQUISAR
  // GET /api/clientes?q={termo}
  // ─────────────────────────────────────────────────────────────────

  Future<List<ClienteModel>> pesquisar(String termo) async {
    if (termo.trim().isEmpty) return listarTodos();
    final uri = Uri.parse('$baseUrl/api/clientes')
        .replace(queryParameters: {'q': termo.trim()});
    try {
      final response = await httpClient.get(uri, headers: _headers);
      _assertOk(response, 'Erro ao pesquisar clientes');
      final lista = jsonDecode(response.body) as List<dynamic>;
      return lista
          .map((e) => ClienteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ClienteServiceException {
      rethrow;
    } catch (e) {
      throw ClienteServiceException('Falha de ligação ao pesquisar clientes: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // BUSCAR POR ID
  // GET /api/clientes/{id}
  // ─────────────────────────────────────────────────────────────────

  Future<ClienteModel> buscarPorId(int id) async {
    final uri = Uri.parse('$baseUrl/api/clientes/$id');
    try {
      final response = await httpClient.get(uri, headers: _headers);
      _assertOk(response, 'Cliente não encontrado');
      return ClienteModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } on ClienteServiceException {
      rethrow;
    } catch (e) {
      throw ClienteServiceException('Falha de ligação ao buscar cliente: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // CRIAR
  // POST /api/clientes
  // ─────────────────────────────────────────────────────────────────

  Future<ClienteModel> criar(ClienteRequestDTO dto) async {
    final uri = Uri.parse('$baseUrl/api/clientes');
    try {
      final response = await httpClient.post(
        uri,
        headers: _headers,
        body: jsonEncode(dto.toJson()),
      );
      _assertOk(response, 'Erro ao criar cliente', esperado: 201);
      return ClienteModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } on ClienteServiceException {
      rethrow;
    } catch (e) {
      throw ClienteServiceException('Falha de ligação ao criar cliente: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // EDITAR
  // PUT /api/clientes/{id}
  // ─────────────────────────────────────────────────────────────────

  Future<ClienteModel> editar(int id, ClienteRequestDTO dto) async {
    final uri = Uri.parse('$baseUrl/api/clientes/$id');
    try {
      final response = await httpClient.put(
        uri,
        headers: _headers,
        body: jsonEncode(dto.toJson()),
      );
      _assertOk(response, 'Erro ao editar cliente');
      return ClienteModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } on ClienteServiceException {
      rethrow;
    } catch (e) {
      throw ClienteServiceException('Falha de ligação ao editar cliente: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // EXCLUIR
  // DELETE /api/clientes/{id}
  // ─────────────────────────────────────────────────────────────────

  Future<void> excluir(int id) async {
    final uri = Uri.parse('$baseUrl/api/clientes/$id');
    try {
      final response = await httpClient.delete(uri, headers: _headers);
      // 204 No Content é o sucesso esperado
      if (response.statusCode == 204) return;
      _assertOk(response, 'Erro ao excluir cliente');
    } on ClienteServiceException {
      rethrow;
    } catch (e) {
      throw ClienteServiceException('Falha de ligação ao excluir cliente: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPER — verifica status e extrai mensagem de erro do backend
  // ─────────────────────────────────────────────────────────────────

  void _assertOk(http.Response response, String fallback,
      {int esperado = 200}) {
    final ok = esperado == 200
        ? response.statusCode >= 200 && response.statusCode < 300
        : response.statusCode == esperado;

    if (ok) return;

    // Tenta extrair mensagem do corpo JSON (Spring Boot devolve { message: "..." })
    String mensagem = fallback;
    try {
      final body = jsonDecode(response.body);
      mensagem = (body as Map<String, dynamic>)['message'] as String? ??
          (body)['error'] as String? ??
          fallback;
    } catch (_) {
      if (response.body.isNotEmpty) mensagem = response.body;
    }

    // Mensagens específicas por código HTTP
    switch (response.statusCode) {
      case 400:
        throw ClienteServiceException('Dados inválidos: $mensagem');
      case 404:
        throw ClienteServiceException('Cliente não encontrado.');
      case 409:
        throw ClienteServiceException(
            'Não é possível excluir: este cliente possui pedidos associados.');
      case 500:
        throw ClienteServiceException(
            'Erro interno do servidor. Tente novamente.');
      default:
        throw ClienteServiceException('$mensagem (HTTP ${response.statusCode})');
    }
  }
}