// lib/features/marca/provider/marca_provider.dart

import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import '../repository/marca_repository.dart';

class MarcaProvider extends ChangeNotifier {
  MarcaProvider({required MarcaRepository repository})
      : _repository = repository;

  final MarcaRepository _repository;

  List<MarcaModel> _marcas     = [];
  bool             _carregando = false;
  String?          _erro;

  List<MarcaModel> get marcas      => List.unmodifiable(_marcas);
  bool             get carregando  => _carregando;
  String?          get erro        => _erro;

  // ── Leitura ───────────────────────────────────────────────────────

  Future<void> carregarMarcas() async {
    _set(carregando: true, erro: null);
    try {
      _marcas = await _repository.listarTodos();
      notifyListeners();
    } catch (e) {
      _set(erro: e.toString());
    } finally {
      _set(carregando: false);
    }
  }

  // ── Escrita ───────────────────────────────────────────────────────

  Future<MarcaModel> criar(MarcaRequestDTO dto) async {
    try {
      final nova = await _repository.criar(dto);
      _marcas.add(nova);
      notifyListeners();
      return nova;
    } catch (e) {
      _set(erro: e.toString());
      rethrow;
    }
  }

  Future<MarcaModel> editar(int id, MarcaRequestDTO dto) async {
    try {
      final editada = await _repository.editar(id, dto);
      final idx = _marcas.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _marcas[idx] = editada;
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
      _marcas.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      _set(erro: e.toString());
      rethrow;
    }
  }

  Future<void> associarCategoria(int idMarca, int idCategoria) async {
    try {
      await _repository.associarCategoria(idMarca, idCategoria);
    } catch (e) {
      _set(erro: e.toString());
      rethrow;
    }
  }

  Future<void> desassociarCategoria(int idMarca, int idCategoria) async {
    try {
      await _repository.desassociarCategoria(idMarca, idCategoria);
    } catch (e) {
      _set(erro: e.toString());
      rethrow;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────

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