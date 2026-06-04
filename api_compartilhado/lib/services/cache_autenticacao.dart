// lib/services/cache_autenticacao.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart'; // ajuste ao caminho real

class CacheAutenticacao {
  CacheAutenticacao._();
  static final CacheAutenticacao instance = CacheAutenticacao._();

  // ── Chaves de armazenamento ───────────────────────────────────────
  static const _kCredencial   = 'auth_cache_credencial';
  static const _kSenhaHash    = 'auth_cache_senha_hash';
  static const _kUsuarioJson  = 'auth_cache_usuario_json';
  static const _kSalvadoEm   = 'auth_cache_salvo_em';

  // ── Guardar após login online bem-sucedido ────────────────────────

  /// Deve ser chamado sempre que o login online for bem-sucedido.
  Future<void> guardar({
    required String credencial,
    required String senhaPlain,
    required UsuarioModel usuario,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCredencial,  credencial);
    await prefs.setString(_kSenhaHash,   _hash(senhaPlain));
    await prefs.setString(_kUsuarioJson, jsonEncode(usuario.toJson()));
    await prefs.setString(_kSalvadoEm,   DateTime.now().toIso8601String());
  }

  // ── Validar credenciais em modo offline ───────────────────────────

  /// Retorna o [UsuarioModel] em cache se as credenciais coincidirem,
  /// ou null se falharem / não houver cache.
  Future<UsuarioModel?> validarOffline({
    required String credencial,
    required String senhaPlain,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final cachedCredencial = prefs.getString(_kCredencial);
    final cachedHash       = prefs.getString(_kSenhaHash);
    final cachedUsuarioStr = prefs.getString(_kUsuarioJson);

    if (cachedCredencial == null ||
        cachedHash       == null ||
        cachedUsuarioStr == null) {
      return null; // sem cache
    }

    final credencialBate = cachedCredencial == credencial;
    final senhaBate      = cachedHash       == _hash(senhaPlain);

    if (!credencialBate || !senhaBate) return null;

    try {
      return UsuarioModel.fromJson(
        jsonDecode(cachedUsuarioStr) as Map<String, dynamic>,
      );
    } catch (_) {
      return null; // cache corrompido
    }
  }

  // ── Limpar cache (ex: logout, reset de senha) ─────────────────────

  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCredencial);
    await prefs.remove(_kSenhaHash);
    await prefs.remove(_kUsuarioJson);
    await prefs.remove(_kSalvadoEm);
  }

  // ── Utilitário ────────────────────────────────────────────────────

  /// SHA-256 da senha — nunca reversível.
  String _hash(String plain) =>
      sha256.convert(utf8.encode(plain)).toString();

  /// Data em que o cache foi guardado (pode ser útil para mostrar aviso).
  Future<DateTime?> get ultimoLoginOnline async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kSalvadoEm);
    return s != null ? DateTime.tryParse(s) : null;
  }

  /// True se existir algum cache guardado.
  Future<bool> get temCache async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kCredencial);
  }
}