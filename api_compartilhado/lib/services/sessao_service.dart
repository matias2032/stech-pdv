import '../models/usuario_model.dart';

class SessaoService {
  SessaoService._();
  static final SessaoService instance = SessaoService._();

  UsuarioModel? _usuario;
  bool _modoOffline = false;

  // ── Getters ───────────────────────────────────────────────────────

  UsuarioModel? get usuario        => _usuario;
  UsuarioModel? get usuarioAtual   => _usuario;
  bool          get temSessao      => _usuario != null;
  bool          get modoOffline    => _modoOffline;

  /// ID do utilizador autenticado. Lança se não houver sessão.
  int get idUsuario {
    assert(_usuario != null, 'SessaoService: nenhum utilizador em sessão.');
    return _usuario!.id;
  }

  // ── Ciclo de vida ─────────────────────────────────────────────────

  /// Login online normal.
  void iniciar(UsuarioModel usuario) {
    _usuario      = usuario;
    _modoOffline  = false;
  }

  /// Login com credenciais em cache (sem servidor).
  void iniciarOffline(UsuarioModel usuario) {
    _usuario      = usuario;
    _modoOffline  = true;
  }

  /// Limpa a sessão (logout).
  void encerrar() {
    _usuario      = null;
    _modoOffline  = false;
  }

  /// Alias para encerrar() — compatibilidade com código existente.
  void limparSessao() => encerrar();
}