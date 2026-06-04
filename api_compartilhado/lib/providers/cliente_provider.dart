// lib/features/cliente/provider/cliente_provider.dart

import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_config.dart';
import 'package:api_compartilhado/models/cliente_model.dart';import 'package:api_compartilhado/models/cliente_model.dart';
import 'package:api_compartilhado/services/cliente_service.dart';
// ═══════════════════════════════════════════════════════════════════
// Estado da listagem
// ═══════════════════════════════════════════════════════════════════

enum ClienteListaStatus { inicial, carregando, sucesso, erro }

class ClienteListaProvider extends ChangeNotifier {
  ClienteListaProvider({required ClienteService service})
      : _service = service;

  final ClienteService _service;

  // ── Estado ────────────────────────────────────────────────────────

  ClienteListaStatus _status = ClienteListaStatus.inicial;
  List<ClienteModel> _clientes = [];
  String?            _erro;
  String             _termoPesquisa = '';
  int?               _filtroPerfil;

  // ── Getters ───────────────────────────────────────────────────────

  ClienteListaStatus get status       => _status;
  List<ClienteModel> get clientes     => _clientes;
  String?            get erro         => _erro;
  bool               get carregando   => _status == ClienteListaStatus.carregando;
  bool               get temErro      => _status == ClienteListaStatus.erro;

  // ── CARREGAR ──────────────────────────────────────────────────────

  Future<void> carregar() async {
    _setStatus(ClienteListaStatus.carregando);
    try {
      if (_termoPesquisa.isNotEmpty) {
        _clientes = await _service.pesquisar(_termoPesquisa);
      } else if (_filtroPerfil != null) {
        _clientes = await _service.listarPorPerfil(_filtroPerfil!);
      } else {
        _clientes = await _service.listarTodos();
      }
      _erro = null;
      _setStatus(ClienteListaStatus.sucesso);
    } on ClienteServiceException catch (e) {
      _erro = e.mensagem;
      _setStatus(ClienteListaStatus.erro);
    }
  }

  // ── PESQUISAR ─────────────────────────────────────────────────────

  Future<void> pesquisar(String termo) async {
    _termoPesquisa = termo;
    _filtroPerfil  = null;
    await carregar();
  }

  void limparPesquisa() {
    _termoPesquisa = '';
    _filtroPerfil  = null;
    carregar();
  }

  // ── FILTRAR POR PERFIL ────────────────────────────────────────────

  Future<void> filtrarPorPerfil(int? idPerfil) async {
    _filtroPerfil  = idPerfil;
    _termoPesquisa = '';
    await carregar();
  }

  // ── REMOVER LOCALMENTE após exclusão confirmada ───────────────────

  void removerLocal(int id) {
    _clientes = _clientes.where((c) => c.id != id).toList();
    notifyListeners();
  }

  // ── UPSERT LOCAL após criação/edição confirmada ───────────────────

  void upsertLocal(ClienteModel cliente) {
    final idx = _clientes.indexWhere((c) => c.id == cliente.id);
    if (idx >= 0) {
      _clientes = List.of(_clientes)..[idx] = cliente;
    } else {
      _clientes = [cliente, ..._clientes];
    }
    notifyListeners();
  }

  // ── Helper ────────────────────────────────────────────────────────

  void _setStatus(ClienteListaStatus s) {
    _status = s;
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════════
// Estado do formulário (criação e edição)
// ═══════════════════════════════════════════════════════════════════

enum ClienteFormStatus { inicial, salvando, sucesso, erro }

class ClienteFormProvider extends ChangeNotifier {
  ClienteFormProvider({required ClienteService service})
      : _service = service;

  final ClienteService _service;

  // ── Estado ────────────────────────────────────────────────────────

  ClienteFormStatus _status  = ClienteFormStatus.inicial;
  String?           _erro;
  ClienteModel?     _salvo;

  // ── Getters ───────────────────────────────────────────────────────

  ClienteFormStatus get status   => _status;
  String?           get erro     => _erro;
  ClienteModel?     get salvo    => _salvo;
  bool              get salvando => _status == ClienteFormStatus.salvando;
  bool              get temErro  => _status == ClienteFormStatus.erro;
  bool              get sucesso  => _status == ClienteFormStatus.sucesso;

  // ── CRIAR ─────────────────────────────────────────────────────────

  Future<void> criar(ClienteRequestDTO dto) async {
    _setStatus(ClienteFormStatus.salvando);
    try {
      _salvo = await _service.criar(dto);
      _erro  = null;
      _setStatus(ClienteFormStatus.sucesso);
    } on ClienteServiceException catch (e) {
      _erro  = e.mensagem;
      _salvo = null;
      _setStatus(ClienteFormStatus.erro);
    }
  }

  // ── EDITAR ────────────────────────────────────────────────────────

  Future<void> editar(int id, ClienteRequestDTO dto) async {
    _setStatus(ClienteFormStatus.salvando);
    try {
      _salvo = await _service.editar(id, dto);
      _erro  = null;
      _setStatus(ClienteFormStatus.sucesso);
    } on ClienteServiceException catch (e) {
      _erro  = e.mensagem;
      _salvo = null;
      _setStatus(ClienteFormStatus.erro);
    }
  }

  // ── RESETAR para reutilizar o provider em novo formulário ─────────

  void resetar() {
    _status = ClienteFormStatus.inicial;
    _erro   = null;
    _salvo  = null;
    notifyListeners();
  }

  // ── Helper ────────────────────────────────────────────────────────

  void _setStatus(ClienteFormStatus s) {
    _status = s;
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════════
// Estado da exclusão
// ═══════════════════════════════════════════════════════════════════

enum ClienteExclusaoStatus { inicial, excluindo, sucesso, erro }

class ClienteExclusaoProvider extends ChangeNotifier {
  ClienteExclusaoProvider({required ClienteService service})
      : _service = service;

  final ClienteService _service;

  // ── Estado ────────────────────────────────────────────────────────

  ClienteExclusaoStatus _status = ClienteExclusaoStatus.inicial;
  String?               _erro;

  // ── Getters ───────────────────────────────────────────────────────

  ClienteExclusaoStatus get status    => _status;
  String?               get erro      => _erro;
  bool                  get excluindo => _status == ClienteExclusaoStatus.excluindo;
  bool                  get temErro   => _status == ClienteExclusaoStatus.erro;
  bool                  get sucesso   => _status == ClienteExclusaoStatus.sucesso;

  // ── EXCLUIR ───────────────────────────────────────────────────────

  Future<void> excluir(int id) async {
    _setStatus(ClienteExclusaoStatus.excluindo);
    try {
      await _service.excluir(id);
      _erro = null;
      _setStatus(ClienteExclusaoStatus.sucesso);
    } on ClienteServiceException catch (e) {
      _erro = e.mensagem;
      _setStatus(ClienteExclusaoStatus.erro);
    }
  }

  void resetar() {
    _status = ClienteExclusaoStatus.inicial;
    _erro   = null;
    notifyListeners();
  }

  void _setStatus(ClienteExclusaoStatus s) {
    _status = s;
    notifyListeners();
  }
}