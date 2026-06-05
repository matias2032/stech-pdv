// lib/features/categoria/provider/categoria_provider.dart

import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_config.dart';
import 'package:api_compartilhado/models/categoria_model.dart';
import '../repository/categoria_repository.dart';

class CategoriaProvider extends ChangeNotifier {
  CategoriaProvider({required CategoriaRepository repository})
      : _repository = repository;

  final CategoriaRepository _repository;

  List<CategoriaModel> _categorias  = [];
  bool                 _carregando  = false;
  String?              _erro;

  List<CategoriaModel> get categorias   => List.unmodifiable(_categorias);
  bool                 get carregando   => _carregando;
  String?              get erro         => _erro;

  Future<void> carregarCategorias() async {
    _set(carregando: true, erro: null);
    try {
      _categorias = await _repository.listarTodos();
      notifyListeners();
    } catch (e) {
      _set(erro: e.toString());
    } finally {
      _set(carregando: false);
    }
  }

  Future<CategoriaModel> criar(CategoriaRequestDTO dto) async {
    try {
      final nova = await _repository.criar(dto);
      _categorias.add(nova);
      notifyListeners();
      return nova;
    } catch (e) {
      _set(erro: e.toString());
      rethrow;
    }
  }

  Future<CategoriaModel> editar(int id, CategoriaRequestDTO dto) async {
    try {
      final editada = await _repository.editar(id, dto);
      final idx = _categorias.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _categorias[idx] = editada;
        notifyListeners();
      }
      return editada;
    } catch (e) {
      _set(erro: e.toString());
      rethrow;
    }
  }

  Future<void> excluir(int id) async {
    try {
      await _repository.excluir(id);
      _categorias.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _set(erro: e.toString());
      rethrow;
    }
  }

  Future<void> associarMarca(int idCategoria, int idMarca) async {
    try {
      await _repository.associarMarca(idCategoria, idMarca);
    } catch (e) {
      _set(erro: e.toString());
      rethrow;
    }
  }

  Future<void> desassociarMarca(int idCategoria, int idMarca) async {
    try {
      await _repository.desassociarMarca(idCategoria, idMarca);
    } catch (e) {
      _set(erro: e.toString());
      rethrow;
    }
  }

  void _set({bool? carregando, String? erro}) {
    if (carregando != null) _carregando = carregando;
    if (erro != null) _erro = erro;
    notifyListeners();
  }

  void limparErro() {
    _erro = null;
    notifyListeners();
  }
}