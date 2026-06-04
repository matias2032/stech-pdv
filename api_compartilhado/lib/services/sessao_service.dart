// lib/services/sessao_service.dart
//
// Guarda o utilizador autenticado durante a sessão.
// Não persiste — limpa ao fechar a app.

import '../models/usuario_model.dart'; // ajuste ao caminho real

class SessaoService {
  SessaoService._();
  static final SessaoService instance = SessaoService._();

  UsuarioModel? _usuario;

  UsuarioModel? get usuario => _usuario;

  /// ID do utilizador autenticado. Lança se não houver sessão.
  int get idUsuario {
    assert(_usuario != null, 'SessaoService: nenhum utilizador em sessão.');
    return _usuario!.id;
  }

  bool get temSessao => _usuario != null;

  UsuarioModel? get usuarioAtual => _usuario;
void limparSessao() => _usuario = null;

  void iniciar(UsuarioModel usuario) => _usuario = usuario;

  void encerrar() => _usuario = null;
}