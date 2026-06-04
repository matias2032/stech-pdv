// lib/providers/usuario_provider.dart

import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_compartilhado.dart'
    show UsuarioModel, UsuarioService; // ← só o necessário, sem ciclo

enum FiltroStatus { todos, ativos, inativos }

class UsuarioProvider extends ChangeNotifier {
  final UsuarioService _service;

  UsuarioProvider({UsuarioService? service})
      : _service = service ?? UsuarioService();

  List<UsuarioModel> _usuarios = [];
  FiltroStatus _filtro = FiltroStatus.todos;
  bool _carregando = false;
  String? _erro;

  List<UsuarioModel> get usuarios => _usuarios;
  FiltroStatus get filtro => _filtro;
  bool get carregando => _carregando;
  String? get erro => _erro;

  List<UsuarioModel> get usuariosFiltrados {
    switch (_filtro) {
      case FiltroStatus.ativos:
        return _usuarios.where((u) => u.ativo).toList();
      case FiltroStatus.inativos:
        return _usuarios.where((u) => !u.ativo).toList();
      case FiltroStatus.todos:
        return List.unmodifiable(_usuarios);
    }
  }

  Future<void> carregarUsuarios() async {
    _setCarregando(true);
    _erro = null;
    try {
      _usuarios = await _service.listar();
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    } finally {
      _setCarregando(false);
    }
  }

  void setFiltro(FiltroStatus novoFiltro) {
    if (_filtro == novoFiltro) return;
    _filtro = novoFiltro;
    notifyListeners();
  }

  Future<void> toggleAtivo(int id) async {
    try {
      final atualizado = await _service.toggleAtivo(id);
      final idx = _usuarios.indexWhere((u) => u.id == id);
      if (idx != -1) {
        _usuarios[idx] = atualizado;
        notifyListeners();
      }
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resetarSenha(int id) async {
    try {
      await _service.resetarSenha(id);
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Adicionar após resetarSenha():

Future<UsuarioModel> criarUsuario(Map<String, dynamic> dados) async {
  try {
    final novo = await _service.criar(dados);
    _usuarios.add(novo);
    notifyListeners();
    return novo;
  } catch (e) {
    _erro = e.toString();
    notifyListeners();
    rethrow;
  }
}

Future<void> alterarSenha(
    int id, String senhaAtual, String novaSenha) async {
  try {
    await _service.alterarSenha(id, senhaAtual, novaSenha);
  } catch (e) {
    _erro = e.toString();
    notifyListeners();
    rethrow;
  }
}

  void _setCarregando(bool valor) {
    _carregando = valor;
    notifyListeners();
  }
}