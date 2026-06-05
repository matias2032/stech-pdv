import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/produto_model.dart';
import '../repository/produto_repository.dart';

enum ProdutoStatus { idle, loading, success, error }

class ProdutoProvider extends ChangeNotifier {
  final ProdutoRepository _repository;

  ProdutoProvider({
    required ProdutoRepository repository,
  }) : _repository = repository;

  List<ProdutoModel> _produtos = [];
  List<ProdutoModel> _produtosAtivos = [];
  ProdutoModel? _produtoActual;

  List<ProdutoImagemModel> _imagens = [];
  List<int> _categoriasDoProduto = [];
  List<int> _marcasDoProduto = [];

  ProdutoStatus _status = ProdutoStatus.idle;
  String? _errorMessage;

  List<ProdutoModel> get produtos => List.unmodifiable(_produtos);
  List<ProdutoModel> get produtosAtivos => List.unmodifiable(_produtosAtivos);
  ProdutoModel? get produtoActual => _produtoActual;

  List<ProdutoImagemModel> get imagens => List.unmodifiable(_imagens);
  List<int> get categoriasDoProduto => List.unmodifiable(_categoriasDoProduto);
  List<int> get marcasDoProduto => List.unmodifiable(_marcasDoProduto);

  ProdutoStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProdutoStatus.loading;

  Future<T?> _run<T>(Future<T> Function() fn) async {
    _status = ProdutoStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await fn();
      _status = ProdutoStatus.success;
      notifyListeners();
      return result;
    } catch (e) {
      _status = ProdutoStatus.error;
      _errorMessage = e.toString();
      debugPrint('❌ ProdutoProvider: $_errorMessage');
      notifyListeners();
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // CRUD BÁSICO — AGORA VIA REPOSITORY
  // ─────────────────────────────────────────────

  Future<ProdutoModel?> criar(ProdutoRequestModel dto) async {
    final result = await _run(() => _repository.criar(dto));

    if (result != null) {
      _produtoActual = result;
      _produtos = [result, ..._produtos];

      if (result.estaAtivo) {
        _produtosAtivos = [result, ..._produtosAtivos];
      }
    }

    return result;
  }

  Future<ProdutoModel?> atualizar(int id, ProdutoRequestModel dto) async {
    final result = await _run(() => _repository.atualizar(id, dto));

    if (result != null) {
      _produtoActual = result;
      _substituirNaLista(result);
    }

    return result;
  }

  Future<bool> toggleAtivo(int id) async {
    await _run(() => _repository.toggleAtivo(id));

    if (_status == ProdutoStatus.success) {
      await buscarPorId(id);
      await listarAtivos();
      return true;
    }

    return false;
  }

  Future<void> listar() async {
    final result = await _run(() => _repository.listarTodos());

    if (result != null) {
      _produtos = result;
    }
  }

  Future<void> listarAtivos() async {
    final result = await _run(() => _repository.listarAtivos());

    if (result != null) {
      _produtosAtivos = result;
    }
  }

  Future<ProdutoModel?> buscarPorId(int id) async {
    final result = await _run(() => _repository.buscarPorId(id));

    if (result != null) {
      _produtoActual = result;
    }

    return result;
  }

  // ─────────────────────────────────────────────
  // CATEGORIAS — ainda requerem internet
  // ─────────────────────────────────────────────

  Future<bool> associarCategoria(int idProduto, int idCategoria) async {
    await _run(() => _repository.associarCategoria(idProduto, idCategoria));

    if (_status == ProdutoStatus.success) {
      if (!_categoriasDoProduto.contains(idCategoria)) {
        _categoriasDoProduto = [..._categoriasDoProduto, idCategoria];
        notifyListeners();
      }
      return true;
    }

    return false;
  }

  Future<bool> desassociarCategoria(int idProduto, int idCategoria) async {
    await _run(() => _repository.desassociarCategoria(idProduto, idCategoria));

    if (_status == ProdutoStatus.success) {
      _categoriasDoProduto =
          _categoriasDoProduto.where((c) => c != idCategoria).toList();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Temporariamente mantidos vazios porque o Repository ainda não tem estes métodos.
  // Depois podemos criar suporte offline/online para categorias e marcas do produto.
  Future<void> carregarCategoriasDoProduto(int idProduto) async {
    _categoriasDoProduto = [];
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // MARCAS — ainda requerem internet
  // ─────────────────────────────────────────────

  Future<bool> associarMarca(int idProduto, int idMarca) async {
    await _run(() => _repository.associarMarca(idProduto, idMarca));

    if (_status == ProdutoStatus.success) {
      if (!_marcasDoProduto.contains(idMarca)) {
        _marcasDoProduto = [..._marcasDoProduto, idMarca];
        notifyListeners();
      }
      return true;
    }

    return false;
  }

  Future<bool> desassociarMarca(int idProduto, int idMarca) async {
    await _run(() => _repository.desassociarMarca(idProduto, idMarca));

    if (_status == ProdutoStatus.success) {
      _marcasDoProduto =
          _marcasDoProduto.where((m) => m != idMarca).toList();
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<void> carregarMarcasDoProduto(int idProduto) async {
    _marcasDoProduto = [];
    notifyListeners();
  }

  Future<List<int>> listarProdutosDaMarca(int idMarca) async {
    return [];
  }

  // ─────────────────────────────────────────────
  // IMAGENS
  // ─────────────────────────────────────────────
  // O ProdutoRepository actual ainda não tem métodos de imagem.
  // Por enquanto, deixei como erro controlado para não chamar API directamente.

  Future<bool> adicionarImagem({
    required int idProduto,
    File? imagemFile,
    Uint8List? imagemBytes,
    required String nomeArquivo,
    String? legenda,
    int imagemPrincipal = 0,
  }) async {
    _status = ProdutoStatus.error;
    _errorMessage =
        'Upload de imagens ainda não está integrado ao ProdutoRepository.';
    notifyListeners();
    return false;
  }

  Future<void> carregarImagens(int idProduto) async {
    _imagens = [];
    notifyListeners();
  }

  Future<bool> definirImagemPrincipal(int idProduto, int idImagem) async {
    _status = ProdutoStatus.error;
    _errorMessage =
        'Definir imagem principal ainda não está integrado ao ProdutoRepository.';
    notifyListeners();
    return false;
  }

  Future<bool> removerImagem(int idImagem) async {
    _status = ProdutoStatus.error;
    _errorMessage =
        'Remover imagem ainda não está integrado ao ProdutoRepository.';
    notifyListeners();
    return false;
  }

  // ─────────────────────────────────────────────
  // UTILITÁRIOS
  // ─────────────────────────────────────────────

  void limparProdutoActual() {
    _produtoActual = null;
    _imagens = [];
    _categoriasDoProduto = [];
    _marcasDoProduto = [];
    notifyListeners();
  }

  void limparErro() {
    _errorMessage = null;
    _status = ProdutoStatus.idle;
    notifyListeners();
  }

  void _substituirNaLista(ProdutoModel actualizado) {
    _produtos = _produtos.map((p) {
      return p.idProduto == actualizado.idProduto ? actualizado : p;
    }).toList();

    if (actualizado.estaAtivo) {
      final existe = _produtosAtivos.any(
        (p) => p.idProduto == actualizado.idProduto,
      );

      if (existe) {
        _produtosAtivos = _produtosAtivos.map((p) {
          return p.idProduto == actualizado.idProduto ? actualizado : p;
        }).toList();
      } else {
        _produtosAtivos = [actualizado, ..._produtosAtivos];
      }
    } else {
      _produtosAtivos = _produtosAtivos
          .where((p) => p.idProduto != actualizado.idProduto)
          .toList();
    }
  }
}