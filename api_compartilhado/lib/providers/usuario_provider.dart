// lib/providers/usuario_provider.dart

import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/models/usuario_model.dart';
import '../repository/usuario_repository.dart';

enum FiltroStatus { todos, ativos, inativos }

class UsuarioProvider extends ChangeNotifier {
  final UsuarioRepository _repository;

  UsuarioProvider({required UsuarioRepository repository})
      : _repository = repository;

  List<UsuarioModel> _usuarios  = [];
  FiltroStatus       _filtro    = FiltroStatus.todos;
  bool               _carregando = false;
  String?            _erro;

  List<UsuarioModel> get usuarios    => _usuarios;
  FiltroStatus       get filtro      => _filtro;
  bool               get carregando  => _carregando;
  String?            get erro        => _erro;

  List<UsuarioModel> get usuariosFiltrados {
    switch (_filtro) {
      case FiltroStatus.ativos:   return _usuarios.where((u) =>  u.ativo).toList();
      case FiltroStatus.inativos: return _usuarios.where((u) => !u.ativo).toList();
      case FiltroStatus.todos:    return List.unmodifiable(_usuarios);
    }
  }

  Future<void> carregarUsuarios() async {
    _setCarregando(true);
    _erro = null;
    try {
      _usuarios = await _repository.listarTodos();
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
      final atualizado = await _repository.toggleAtivo(id);
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
      await _repository.resetarSenha(id);
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<UsuarioModel> criarUsuario(UsuarioRequestDTO dto) async {
    try {
      final novo = await _repository.criar(dto);
      _usuarios.add(novo);
      notifyListeners();
      return novo;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<UsuarioModel> atualizarUsuario(int id, UsuarioRequestDTO dto) async {
  try {
    final atualizado = await _repository.atualizar(id, dto);
    final idx = _usuarios.indexWhere((u) => u.id == id);
    if (idx != -1) {
      _usuarios[idx] = atualizado;
    } else {
      _usuarios.add(atualizado);
    }
    notifyListeners();
    return atualizado;
  } catch (e) {
    _erro = e.toString();
    notifyListeners();
    rethrow;
  }
}



  Future<void> alterarSenha(int id, AlterarSenhaDTO dto) async {
    try {
      await _repository.alterarSenha(id, dto);
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