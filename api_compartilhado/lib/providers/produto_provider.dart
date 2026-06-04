import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/produto_model.dart';
import '../services/produto_service.dart';

enum ProdutoStatus { idle, loading, success, error }

/// Provider de produtos.
///
/// Expõe toda a superfície do [ProdutoService] com gestão de estado
/// reactiva via [ChangeNotifier]:
///
///  • [produtos]           — lista completa (activos + inactivos)
///  • [produtosAtivos]     — apenas os activos
///  • [produtoActual]      — produto em foco (detalhe / edição)
///  • [imagens]            — imagens do produto em foco
///  • [categoriasDoProduto] — ids de categorias do produto em foco
///  • [marcasDoProduto]    — ids de marcas do produto em foco
///  • [status]             — estado da última operação
///  • [errorMessage]       — mensagem de erro
class ProdutoProvider extends ChangeNotifier {
  // ── Dependência ──────────────────────────────────────────────────────────
  final ProdutoService _service;

  ProdutoProvider({ProdutoService? service})
      : _service = service ?? ProdutoService.instance;

  // ── Estado ───────────────────────────────────────────────────────────────
  List<ProdutoModel> _produtos = [];
  List<ProdutoModel> _produtosAtivos = [];
  ProdutoModel? _produtoActual;
  List<ProdutoImagemModel> _imagens = [];
  List<int> _categoriasDoProduto = [];
  List<int> _marcasDoProduto = [];

  ProdutoStatus _status = ProdutoStatus.idle;
  String? _errorMessage;

  // ── Getters ──────────────────────────────────────────────────────────────
  List<ProdutoModel> get produtos => List.unmodifiable(_produtos);
  List<ProdutoModel> get produtosAtivos => List.unmodifiable(_produtosAtivos);
  ProdutoModel? get produtoActual => _produtoActual;
  List<ProdutoImagemModel> get imagens => List.unmodifiable(_imagens);
  List<int> get categoriasDoProduto =>
      List.unmodifiable(_categoriasDoProduto);
  List<int> get marcasDoProduto => List.unmodifiable(_marcasDoProduto);
  ProdutoStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProdutoStatus.loading;

  // ── Helper ────────────────────────────────────────────────────────────────
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

  // ════════════════════════════════════════════════════════════════════════
  // CRUD BÁSICO
  // ════════════════════════════════════════════════════════════════════════

  /// POST /api/produtos
  Future<ProdutoModel?> criar(ProdutoRequestModel dto) async {
    final result = await _run(() => _service.criar(dto));
    if (result != null) {
      _produtoActual = result;
      _produtos = [result, ..._produtos];
      if (result.estaAtivo) _produtosAtivos = [result, ..._produtosAtivos];
    }
    return result;
  }

  /// PUT /api/produtos/{id}
  Future<ProdutoModel?> atualizar(int id, ProdutoRequestModel dto) async {
    final result = await _run(() => _service.atualizar(id, dto));
    if (result != null) {
      _produtoActual = result;
      _substituirNaLista(result);
    }
    return result;
  }

  /// PATCH /api/produtos/{id}/toggle-ativo
  /// Inverte o estado activo e re-sincroniza as listas locais.
  Future<bool> toggleAtivo(int id) async {
    await _run(() => _service.toggleAtivo(id));
    if (_status == ProdutoStatus.success) {
      // Recarrega o produto actualizado para reflectir o novo estado
      await buscarPorId(id);
      return true;
    }
    return false;
  }

  /// GET /api/produtos
  Future<void> listar() async {
    final result = await _run(() => _service.listar());
    if (result != null) _produtos = result;
  }

  /// GET /api/produtos/ativos
  Future<void> listarAtivos() async {
    final result = await _run(() => _service.listarAtivos());
    if (result != null) _produtosAtivos = result;
  }

  /// GET /api/produtos/{id}
  Future<ProdutoModel?> buscarPorId(int id) async {
    final result = await _run(() => _service.buscarPorId(id));
    if (result != null) _produtoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // CATEGORIAS
  // ════════════════════════════════════════════════════════════════════════

  /// POST /api/produtos/{idProduto}/categorias/{idCategoria}
  Future<bool> associarCategoria(int idProduto, int idCategoria) async {
    await _run(() => _service.associarCategoria(idProduto, idCategoria));
    if (_status == ProdutoStatus.success) {
      if (!_categoriasDoProduto.contains(idCategoria)) {
        _categoriasDoProduto = [..._categoriasDoProduto, idCategoria];
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  /// DELETE /api/produtos/{idProduto}/categorias/{idCategoria}
  Future<bool> desassociarCategoria(int idProduto, int idCategoria) async {
    await _run(() => _service.desassociarCategoria(idProduto, idCategoria));
    if (_status == ProdutoStatus.success) {
      _categoriasDoProduto =
          _categoriasDoProduto.where((c) => c != idCategoria).toList();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// GET /api/produtos/{idProduto}/categorias
  Future<void> carregarCategoriasDoProduto(int idProduto) async {
    final result =
        await _run(() => _service.listarCategoriasDoProduto(idProduto));
    if (result != null) _categoriasDoProduto = result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // MARCAS
  // ════════════════════════════════════════════════════════════════════════

  /// POST /api/produtos/{idProduto}/marcas/{idMarca}
  Future<bool> associarMarca(int idProduto, int idMarca) async {
    await _run(() => _service.associarMarca(idProduto, idMarca));
    if (_status == ProdutoStatus.success) {
      if (!_marcasDoProduto.contains(idMarca)) {
        _marcasDoProduto = [..._marcasDoProduto, idMarca];
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  /// DELETE /api/produtos/{idProduto}/marcas/{idMarca}
  Future<bool> desassociarMarca(int idProduto, int idMarca) async {
    await _run(() => _service.desassociarMarca(idProduto, idMarca));
    if (_status == ProdutoStatus.success) {
      _marcasDoProduto =
          _marcasDoProduto.where((m) => m != idMarca).toList();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// GET /api/produtos/{idProduto}/marcas
  Future<void> carregarMarcasDoProduto(int idProduto) async {
    final result =
        await _run(() => _service.listarMarcasDoProduto(idProduto));
    if (result != null) _marcasDoProduto = result;
  }

  /// GET /api/produtos/marcas/{idMarca}/produtos
  Future<List<int>> listarProdutosDaMarca(int idMarca) async {
    final result =
        await _run(() => _service.listarProdutosDaMarca(idMarca));
    return result ?? [];
  }

  // ════════════════════════════════════════════════════════════════════════
  // IMAGENS
  // ════════════════════════════════════════════════════════════════════════

  /// POST /api/produtos/{idProduto}/imagens  (multipart)
  Future<bool> adicionarImagem({
    required int idProduto,
    File? imagemFile,
    Uint8List? imagemBytes,
    required String nomeArquivo,
    String? legenda,
    int imagemPrincipal = 0,
  }) async {
    await _run(() => _service.adicionarImagem(
          idProduto: idProduto,
          imagemFile: imagemFile,
          imagemBytes: imagemBytes,
          nomeArquivo: nomeArquivo,
          legenda: legenda,
          imagemPrincipal: imagemPrincipal,
        ));
    if (_status == ProdutoStatus.success) {
      await carregarImagens(idProduto);
      return true;
    }
    return false;
  }

  /// GET /api/produtos/{idProduto}/imagens
  Future<void> carregarImagens(int idProduto) async {
    final result = await _run(() => _service.listarImagens(idProduto));
    if (result != null) _imagens = result;
  }

  /// PATCH /api/produtos/{idProduto}/imagens/{idImagem}/principal
  Future<bool> definirImagemPrincipal(int idProduto, int idImagem) async {
    await _run(() => _service.definirImagemPrincipal(idProduto, idImagem));
    if (_status == ProdutoStatus.success) {
      // Actualiza estado local: marca o principal e limpa os outros
      _imagens = _imagens.map((img) {
        return ProdutoImagemModel(
          idImagem: img.idImagem,
          idProduto: img.idProduto,
          caminhoImagem: img.caminhoImagem,
          legenda: img.legenda,
          imagemPrincipal: img.idImagem == idImagem ? 1 : 0,
        );
      }).toList();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// DELETE /api/produtos/imagens/{idImagem}
  Future<bool> removerImagem(int idImagem) async {
    await _run(() => _service.removerImagem(idImagem));
    if (_status == ProdutoStatus.success) {
      _imagens = _imagens.where((img) => img.idImagem != idImagem).toList();
      notifyListeners();
      return true;
    }
    return false;
  }

  // ════════════════════════════════════════════════════════════════════════
  // UTILITÁRIOS
  // ════════════════════════════════════════════════════════════════════════

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

  // ── Substitui um produto nas listas locais após edição ────────────────
  void _substituirNaLista(ProdutoModel actualizado) {
    _produtos = _produtos.map((p) {
      return p.idProduto == actualizado.idProduto ? actualizado : p;
    }).toList();
    _produtosAtivos = _produtosAtivos
        .where((p) => p.idProduto != actualizado.idProduto || actualizado.estaAtivo)
        .map((p) => p.idProduto == actualizado.idProduto ? actualizado : p)
        .toList();
  }
}