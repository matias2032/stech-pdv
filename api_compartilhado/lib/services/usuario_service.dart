// lib/features/usuario/services/usuario_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_compartilhado.dart';

class UsuarioService {
  final http.Client _client;

  UsuarioService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<UsuarioModel>> listar({bool? ativo}) async {
    final uri = Uri.parse(ApiConfig.usuariosUrl).replace(     // ← usuariosUrl
      queryParameters: ativo != null ? {'ativo': ativo.toString()} : null,
    );
    final response = await _client.get(uri, headers: ApiConfig.defaultHeaders);
    _checkStatus(response);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => UsuarioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UsuarioModel> buscarPorId(int id) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.usuariosUrl}/$id'),              // ← usuariosUrl
      headers: ApiConfig.defaultHeaders,
    );
    _checkStatus(response);
    return UsuarioModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<UsuarioModel> toggleAtivo(int id) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.usuariosUrl}/$id/toggle-ativo'), // ← usuariosUrl
      headers: ApiConfig.defaultHeaders,
    );
    _checkStatus(response);
    return UsuarioModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> resetarSenha(int id) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.usuariosUrl}/$id/reset-senha'),  // ← usuariosUrl
      headers: ApiConfig.defaultHeaders,
    );
    _checkStatus(response);
  }

  // Adicionar após resetarSenha():

Future<UsuarioModel> criar(Map<String, dynamic> dados) async {
  final response = await _client.post(
    Uri.parse(ApiConfig.usuariosUrl),
    headers: ApiConfig.defaultHeaders,
    body: jsonEncode(dados),
  );
  _checkStatus(response);
  return UsuarioModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>);
}

Future<void> alterarSenha(
    int id, String senhaAtual, String novaSenha) async {
  final response = await _client.post(
    Uri.parse('${ApiConfig.usuariosUrl}/$id/alterar-senha'),
    headers: ApiConfig.defaultHeaders,
    body: jsonEncode({
      'senhaAtual': senhaAtual,
      'novaSenha': novaSenha,
    }),
  );
  _checkStatus(response);
}

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Erro na requisição: ${response.statusCode} — ${response.body}');
    }
  }

  Future<UsuarioModel> atualizar(int id, Map<String, dynamic> dados) async {
  final response = await _client.put(
    Uri.parse('${ApiConfig.usuariosUrl}/$id'),
    headers: ApiConfig.defaultHeaders,
    body: jsonEncode(dados),
  );
  _checkStatus(response);
  return UsuarioModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>);
}
}