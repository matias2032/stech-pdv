// lib/providers/cotacao_provider.dart

import 'package:flutter/foundation.dart';

import '../models/cotacao_model.dart';
import '../models/pedido_model.dart';
import '../repository/cotacao_repository.dart';

enum CotacaoStatus { idle, loading, success, error }

class CotacaoProvider extends ChangeNotifier {
  // ── Dependência ──────────────────────────────────────────────────────────
  final CotacaoRepository _repository;

  CotacaoProvider({required CotacaoRepository repository})
      : _repository = repository;

  // ── Estado ───────────────────────────────────────────────────────────────
  CotacaoModel?       _cotacaoActual;
  List<CotacaoModel>  _cotacoes = [];

  CotacaoStatus _status = CotacaoStatus.idle;
  String?       _errorMessage;

  // ── Getters ──────────────────────────────────────────────────────────────
  CotacaoModel?      get cotacaoActual => _cotacaoActual;
  List<CotacaoModel> get cotacoes      => List.unmodifiable(_cotacoes);
  CotacaoStatus      get status        => _status;
  String?            get errorMessage  => _errorMessage;
  bool               get isLoading     => _status == CotacaoStatus.loading;

  // ── Helper ────────────────────────────────────────────────────────────────
  Future<T?> _run<T>(Future<T> Function() fn) async {
    _status = CotacaoStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await fn();
      _status = CotacaoStatus.success;
      notifyListeners();
      return result;
    } catch (e) {
      _status = CotacaoStatus.error;
      _errorMessage = e.toString();
      debugPrint('❌ CotacaoProvider: $_errorMessage');
      notifyListeners();
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // CRIAR COTAÇÃO
  // ════════════════════════════════════════════════════════════════════════

  Future<CotacaoModel?> criarCotacao(CriarCotacaoRequestModel dto) async {
    final result = await _run(() => _repository.criarCotacao(dto));
    if (result != null) _cotacaoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // CONSULTAS
  // ════════════════════════════════════════════════════════════════════════

  Future<CotacaoModel?> buscarPorId(int idCotacao) async {
    final result = await _run(() => _repository.buscarPorId(idCotacao));
    if (result != null) _cotacaoActual = result;
    return result;
  }

  Future<void> listarTodas() async {
    final result = await _run(() => _repository.listarTodas());
    if (result != null) _cotacoes = result;
  }

  Future<void> listarPorStatus(String status) async {
    final result = await _run(() => _repository.listarPorStatus(status));
    if (result != null) _cotacoes = result;
  }

  Future<void> listarPorCliente(int idCliente) async {
    final result = await _run(() => _repository.listarPorCliente(idCliente));
    if (result != null) _cotacoes = result;
  }

  Future<void> listarPorUsuario(int idUsuario) async {
    final result = await _run(() => _repository.listarPorUsuario(idUsuario));
    if (result != null) _cotacoes = result;
  }

  Future<void> listarProntas() async {
  final result = await _run(() => _repository.listarProntas());
  if (result != null) _cotacoes = result;
}

  // ════════════════════════════════════════════════════════════════════════
  // ACTUALIZAR COTAÇÃO
  // ════════════════════════════════════════════════════════════════════════

  Future<CotacaoModel?> atualizarCotacao(
    int idCotacao,
    AtualizarCotacaoRequestModel dto,
  ) async {
    final result = await _run(() => _repository.atualizarCotacao(idCotacao, dto));
    if (result != null) _cotacaoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // EXCLUIR COTAÇÃO
  // ════════════════════════════════════════════════════════════════════════

  Future<bool> excluirCotacao(int idCotacao) async {
    await _run(() => _repository.excluirCotacao(idCotacao));
    if (_status == CotacaoStatus.success) {
      _cotacoes = _cotacoes.where((c) => c.idCotacao != idCotacao).toList();
      if (_cotacaoActual?.idCotacao == idCotacao) _cotacaoActual = null;
      notifyListeners();
    }
    return _status == CotacaoStatus.success;
  }

  // ════════════════════════════════════════════════════════════════════════
  // ITENS DE PRODUTO
  // ════════════════════════════════════════════════════════════════════════

  Future<CotacaoModel?> adicionarProduto(
    int idCotacao,
    AdicionarProdutoCotacaoRequestModel dto,
  ) async {
    final result = await _run(() => _repository.adicionarProduto(idCotacao, dto));
    if (result != null) _cotacaoActual = result;
    return result;
  }

  Future<CotacaoModel?> atualizarItemProduto(
    int idCotacao,
    int idItem,
    AtualizarItemCotacaoRequestModel dto,
  ) async {
    final result =
        await _run(() => _repository.atualizarItemProduto(idCotacao, idItem, dto));
    if (result != null) _cotacaoActual = result;
    return result;
  }

  Future<CotacaoModel?> removerItemProduto(int idCotacao, int idItem) async {
    final result = await _run(() => _repository.removerItemProduto(idCotacao, idItem));
    if (result != null) _cotacaoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // ITENS DE SERVIÇO
  // ════════════════════════════════════════════════════════════════════════

  Future<CotacaoModel?> adicionarServico(
    int idCotacao,
    AdicionarServicoCotacaoRequestModel dto,
  ) async {
    final result = await _run(() => _repository.adicionarServico(idCotacao, dto));
    if (result != null) _cotacaoActual = result;
    return result;
  }

  Future<CotacaoModel?> atualizarItemServico(
    int idCotacao,
    int idItem,
    AtualizarItemCotacaoRequestModel dto,
  ) async {
    final result =
        await _run(() => _repository.atualizarItemServico(idCotacao, idItem, dto));
    if (result != null) _cotacaoActual = result;
    return result;
  }

  Future<CotacaoModel?> removerItemServico(int idCotacao, int idItem) async {
    final result = await _run(() => _repository.removerItemServico(idCotacao, idItem));
    if (result != null) _cotacaoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // CONVERSÃO EM PEDIDO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> converterEmPedido(
    int idCotacao,
    ConverterCotacaoEmPedidoRequestModel dto,
  ) async {
    final result = await _run(() => _repository.converterEmPedido(idCotacao, dto));
    if (result != null) {
      // a cotação foi convertida — remove-a da lista de abertas e limpa o actual
      _cotacoes = _cotacoes.where((c) => c.idCotacao != idCotacao).toList();
      if (_cotacaoActual?.idCotacao == idCotacao) _cotacaoActual = null;
      notifyListeners();
    }
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // UTILITÁRIOS
  // ════════════════════════════════════════════════════════════════════════

  void limparCotacaoActual() {
    _cotacaoActual = null;
    notifyListeners();
  }

  void limparCotacoes() {
    _cotacoes = [];
    notifyListeners();
  }

  void limparErro() {
    _errorMessage = null;
    _status = CotacaoStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}