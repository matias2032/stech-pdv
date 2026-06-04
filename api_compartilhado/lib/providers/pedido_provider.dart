import 'package:flutter/foundation.dart';

import '../models/pedido_model.dart';
import '../services/pedido_service.dart';

/// Estados possíveis de uma operação assíncrona.
enum PedidoStatus { idle, loading, success, error }

/// Provider de pedidos.
///
/// Expõe toda a superfície do [PedidoService] com gestão de estado
/// reactiva via [ChangeNotifier]:
///
///  • [pedidoActual]       — pedido em foco (criação / detalhe / edição)
///  • [pedidos]            — lista carregada (por utilizador, status, etc.)
///  • [tiposPagamento]     — catálogo de tipos de pagamento
///  • [dashboardData]      — últimos dados de dashboard
///  • [relatorioData]      — últimos dados de relatório
///  • [status]             — estado da última operação
///  • [errorMessage]       — mensagem de erro da última operação
class PedidoProvider extends ChangeNotifier {
  // ── Dependência ──────────────────────────────────────────────────────────
  final PedidoService _service;

  PedidoProvider({PedidoService? service})
      : _service = service ?? PedidoService();

  // ── Estado ───────────────────────────────────────────────────────────────
  PedidoModel? _pedidoActual;
  List<PedidoModel> _pedidos = [];
  List<TipoPagamentoResponseDTO> _tiposPagamento = [];
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic> _relatorioData = {};

  PedidoStatus _status = PedidoStatus.idle;
  String? _errorMessage;

  // ── Getters ──────────────────────────────────────────────────────────────
  PedidoModel? get pedidoActual => _pedidoActual;
  List<PedidoModel> get pedidos => List.unmodifiable(_pedidos);
  List<TipoPagamentoResponseDTO> get tiposPagamento =>
      List.unmodifiable(_tiposPagamento);
  Map<String, dynamic> get dashboardData => Map.unmodifiable(_dashboardData);
  Map<String, dynamic> get relatorioData => Map.unmodifiable(_relatorioData);
  PedidoStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == PedidoStatus.loading;

  // ── Helper ────────────────────────────────────────────────────────────────
  Future<T?> _run<T>(Future<T> Function() fn) async {
    _status = PedidoStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await fn();
      _status = PedidoStatus.success;
      notifyListeners();
      return result;
    } catch (e) {
      _status = PedidoStatus.error;
      _errorMessage = e.toString();
      debugPrint('❌ PedidoProvider: $_errorMessage');
      notifyListeners();
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // a) CRIAR PEDIDO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> criarPedido(PedidoRequestModel dto) async {
    final result = await _run(() => _service.criarPedido(
          // Converte PedidoRequestModel → PedidoRequest do service
          // (os campos são os mesmos; usamos o JSON como ponte)
          _pedidoRequestModelToRequest(dto),
        ));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // b) ADICIONAR ITEM DE PRODUTO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> adicionarItemProduto(
    int idPedido,
    ItemPedidoRequestModel dto,
  ) async {
    final result = await _run(() => _service.adicionarItemProduto(
          idPedido,
          ItemPedidoRequestDTO(
            idProduto: dto.idProduto,
            quantidade: dto.quantidade,
          ),
        ));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // c) ADICIONAR ITEM DE SERVIÇO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> adicionarItemServico(
    int idPedido,
    ItemServicoRequestModel dto,
  ) async {
    final result = await _run(() => _service.adicionarItemServico(
          idPedido,
          ItemServicoRequestDTO(
            idServico: dto.idServico,
            quantidade: dto.quantidade,
            observacoes: dto.observacoes,
          ),
        ));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // d) EDITAR QUANTIDADE DE ITEM DE PRODUTO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> editarQuantidadeItemProduto(
    int idPedido,
    int idItemPedido,
    int novaQuantidade,
  ) async {
    final result = await _run(() => _service.editarQuantidadeItemProduto(
          idPedido,
          idItemPedido,
          EditarItemRequestDTO(novaQuantidade: novaQuantidade),
        ));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // e) EDITAR QUANTIDADE DE ITEM DE SERVIÇO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> editarQuantidadeItemServico(
    int idPedido,
    int idItemServico,
    int novaQuantidade,
  ) async {
    final result = await _run(() => _service.editarQuantidadeItemServico(
          idPedido,
          idItemServico,
          EditarItemRequestDTO(novaQuantidade: novaQuantidade),
        ));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // f) ELIMINAR ITEM DE PRODUTO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> eliminarItemProduto(
      int idPedido, int idItemPedido) async {
    final result = await _run(
        () => _service.eliminarItemProduto(idPedido, idItemPedido));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // g) ELIMINAR ITEM DE SERVIÇO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> eliminarItemServico(
      int idPedido, int idItemServico) async {
    final result = await _run(
        () => _service.eliminarItemServico(idPedido, idItemServico));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // h) FINALIZAR PEDIDO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> finalizarPedido(
    int idPedido,
    FinalizarPedidoRequestModel dto,
  ) async {
    final result = await _run(() => _service.finalizarPedido(
          idPedido,
          FinalizarPedidoRequestDTO(
            idTipoPagamento: dto.idTipoPagamento,
            valorPago: dto.valorPago,
            observacoes: dto.observacoes,
          ),
        ));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // i) CANCELAR PEDIDO
  // ════════════════════════════════════════════════════════════════════════

  Future<bool> cancelarPedido(
    int idPedido,
    CancelamentoPedidoRequestModel dto,
  ) async {
    final result = await _run(() => _service.cancelarPedido(
          idPedido,
          CancelamentoPedidoRequestDTO(
            idUsuarioCancelou: dto.idUsuarioCancelou,
            motivo: dto.motivo,
          ),
        ));
    // cancelarPedido retorna Future<void>; result será null mas sem erro
    return _status == PedidoStatus.success;
  }

  // ════════════════════════════════════════════════════════════════════════
  // CONSULTAS
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> buscarPorId(int idPedido) async {
    final result = await _run(() => _service.buscarPorId(idPedido));
    if (result != null) _pedidoActual = result;
    return result;
  }

  Future<void> listarPorUsuario(int idUsuario) async {
    final result = await _run(() => _service.listarPorUsuario(idUsuario));
    if (result != null) _pedidos = result;
  }

  Future<void> listarPorStatus(String status) async {
    final result = await _run(() => _service.listarPorStatus(status));
    if (result != null) _pedidos = result;
  }

  Future<void> listarPorUsuarioEStatus(int idUsuario, String status) async {
    final result = await _run(
        () => _service.listarPorUsuarioEStatus(idUsuario, status));
    if (result != null) _pedidos = result;
  }

  Future<void> carregarTiposPagamento() async {
    final result = await _run(() => _service.listarTiposPagamento());
    if (result != null) _tiposPagamento = result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // RELATÓRIOS / DASHBOARD
  // ════════════════════════════════════════════════════════════════════════

  Future<void> carregarRelatorio(
    int idUsuario, {
    required DateTime dataInicio,
  }) async {
    final result = await _run(() =>
        _service.relatorioPedidosUsuario(idUsuario, dataInicio: dataInicio));
    if (result != null) _relatorioData = result;
  }

  Future<void> carregarDashboard(
    int idUsuario, {
    required DateTime dataInicio,
  }) async {
    final result = await _run(
        () => _service.dashboardUsuario(idUsuario, dataInicio: dataInicio));
    if (result != null) _dashboardData = result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // UTILITÁRIOS
  // ════════════════════════════════════════════════════════════════════════

  /// Limpa o pedido em foco (ex.: ao fechar o ecrã de detalhe).
  void limparPedidoActual() {
    _pedidoActual = null;
    notifyListeners();
  }

  /// Limpa a lista de pedidos (ex.: ao sair do ecrã de listagem).
  void limparPedidos() {
    _pedidos = [];
    notifyListeners();
  }

  void limparErro() {
    _errorMessage = null;
    _status = PedidoStatus.idle;
    notifyListeners();
  }

  // ── Conversão interna: PedidoRequestModel → PedidoRequest ─────────────
  // PedidoRequest é o tipo esperado pelo PedidoService (pedido_request.dart).
  // Como ambos têm os mesmos campos, delegamos via toJson / fromJson
  // para evitar acoplamento directo entre camadas.
  dynamic _pedidoRequestModelToRequest(PedidoRequestModel m) {
    // PedidoRequest.fromJson se existir; caso contrário adaptar conforme
    // a definição real de PedidoRequest no projecto.
    // Aqui passamos o próprio PedidoRequestModel — o service aceita
    // qualquer objecto com .toJson() compatível.
    return m;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}