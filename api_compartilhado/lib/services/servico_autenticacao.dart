// lib/services/servico_autenticacao.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_config.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

class ServicoAutenticacao {

  Future<ResultadoAutenticacao> login(String credencial, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({'credencial': credencial, 'senha': password}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final usuario = UsuarioModel.fromJson(json['usuario']);

        if (json['primeiraSenha'] == true) {
          return ResultadoAutenticacao(
            status: StatusAutenticacao.primeiraSenha,
            mensagem: 'Você precisa definir uma nova senha.',
            usuario: usuario,
          );
        }

        return ResultadoAutenticacao(
          status: StatusAutenticacao.sucesso,
          mensagem: 'Login realizado com sucesso!',
          usuario: usuario,
        );
      }

      if (response.statusCode == 401) {
        final json = jsonDecode(response.body);
        return ResultadoAutenticacao(
          status: StatusAutenticacao.credenciaisInvalidas,
          mensagem: json['message'] ?? 'Credencial ou senha incorretos.',
        );
      }

      return ResultadoAutenticacao(
        status: StatusAutenticacao.erroDesconhecido,
        mensagem: 'Erro inesperado (${response.statusCode})',
      );
    } catch (e) {
      return ResultadoAutenticacao(
        status: StatusAutenticacao.erroDesconhecido,
        mensagem: 'Erro de conexão: $e',
      );
    }
  }

  Future<bool> trocarPrimeiraSenha(int idUsuario, String novaSenha) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/$idUsuario/trocar-senha'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({'novaSenha': novaSenha}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}