// lib/services/servico_autenticacao.dart


import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_config.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'cache_autenticacao.dart'; // ajuste ao caminho real

class ServicoAutenticacao {
  final _cache = CacheAutenticacao.instance;

  // ── Login principal ───────────────────────────────────────────────

  Future<ResultadoAutenticacao> login(
    String credencial,
    String password,
  ) async {
    // ── 1. Tentativa online ──────────────────────────────────────────
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode({'credencial': credencial, 'senha': password}),
          )
          .timeout(ApiConfig.timeout);

      // ── 2. Login online bem-sucedido ─────────────────────────────
      if (response.statusCode == 200) {
        final json    = jsonDecode(response.body) as Map<String, dynamic>;
        final usuario = UsuarioModel.fromJson(
          json['usuario'] as Map<String, dynamic>,
        );

        // Guardar em cache para uso offline futuro
        await _cache.guardar(
          credencial:  credencial,
          senhaPlain:  password,
          usuario:     usuario,
        );

        if (json['primeiraSenha'] == true) {
          return ResultadoAutenticacao(
            status:   StatusAutenticacao.primeiraSenha,
            mensagem: 'Você precisa definir uma nova senha.',
            usuario:  usuario,
          );
        }

        return ResultadoAutenticacao(
          status:   StatusAutenticacao.sucesso,
          mensagem: 'Login realizado com sucesso!',
          usuario:  usuario,
        );
      }

      // ── 3. Credenciais erradas (servidor respondeu 401) ──────────
      if (response.statusCode == 401) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ResultadoAutenticacao(
          status:   StatusAutenticacao.credenciaisInvalidas,
          mensagem: json['message'] as String? ??
              'Credencial ou senha incorretos.',
        );
      }

      // ── 4. Outro erro HTTP ────────────────────────────────────────
      return ResultadoAutenticacao(
        status:   StatusAutenticacao.erroDesconhecido,
        mensagem: 'Erro inesperado (${response.statusCode}).',
      );

    // ── 5. Sem rede → fallback offline ──────────────────────────────
    } on SocketException catch (_) {
      return _tentarLoginOffline(credencial, password);
    } on http.ClientException catch (e) {
      // ClientException também cobre "Failed host lookup" no Windows/mobile
      if (_pareceSemRede(e.message)) {
        return _tentarLoginOffline(credencial, password);
      }
      return ResultadoAutenticacao(
        status:   StatusAutenticacao.erroDesconhecido,
        mensagem: 'Erro de conexão: ${e.message}',
      );
    } catch (e) {
      return ResultadoAutenticacao(
        status:   StatusAutenticacao.erroDesconhecido,
        mensagem: 'Erro inesperado: $e',
      );
    }
  }

  // ── Troca de primeira senha ───────────────────────────────────────

  Future<bool> trocarPrimeiraSenha(int idUsuario, String novaSenha) async {
    try {
      final response = await http.patch(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/auth/$idUsuario/trocar-senha'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({'novaSenha': novaSenha}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Privado: validação offline ────────────────────────────────────

  Future<ResultadoAutenticacao> _tentarLoginOffline(
    String credencial,
    String password,
  ) async {
    final usuario = await _cache.validarOffline(
      credencial: credencial,
      senhaPlain: password,
    );

    if (usuario == null) {
      // Não há cache ou as credenciais não batem
      final temCache = await _cache.temCache;
      return ResultadoAutenticacao(
        status: StatusAutenticacao.erroDesconhecido,
        mensagem: temCache
            ? 'Sem conexão. As credenciais introduzidas não coincidem '
              'com o último utilizador que iniciou sessão neste dispositivo.'
            : 'Sem conexão com o servidor. Faça login online pelo menos '
              'uma vez para activar o modo offline.',
      );
    }

    // Cache válido — sessão offline
    final ultimoLogin = await _cache.ultimoLoginOnline;
    final aviso = ultimoLogin != null
        ? 'Último login online: ${_formatarData(ultimoLogin)}.'
        : '';

    return ResultadoAutenticacao(
      status:      StatusAutenticacao.sucesso,
      mensagem:    'A trabalhar em modo offline. $aviso'.trim(),
      usuario:     usuario,
      modoOffline: true,          // ← flag nova (ver ResultadoAutenticacao)
    );
  }

  // ── Utilitários ───────────────────────────────────────────────────

  /// Detecta mensagens típicas de "sem rede" no ClientException.
  bool _pareceSemRede(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('failed host lookup') ||
        lower.contains('no such host') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('errno = 11001') || // Windows: WSAHOST_NOT_FOUND
        lower.contains('errno = 7');       // Android: EAFNOSUPPORT
  }

  String _formatarData(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}