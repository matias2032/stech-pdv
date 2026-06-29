// lib/providers/pedido_provider.dart

import 'package:flutter/foundation.dart';

import '../models/pedido_model.dart';
import '../services/pedido_service.dart';
import '../repository/pedido_repository.dart';
import 'produto_provider.dart';
import '../core/database/daos/produto_dao.dart';
import '../controllers/pedido_ativo_controller.dart';

enum PedidoStatus { idle, loading, success, error }

class PedidoProvider extends ChangeNotifier {
  // ── Dependência ──────────────────────────────────────────────────────────
  final PedidoRepository _repository;
  final ProdutoProvider _produtoProvider;
  
PedidoProvider({
  required PedidoRepository repository,
  required ProdutoProvider produtoProvider,  // ← novo parâmetro
}) : _repository = repository,
     _produtoProvider = produtoProvider;

      

  // ── Estado ───────────────────────────────────────────────────────────────
  PedidoModel?                    _pedidoActual;
  List<PedidoModel>               _pedidos        = [];
  List<TipoPagamentoResponseDTO>  _tiposPagamento = [];
  Map<String, dynamic>            _dashboardData  = {};
  Map<String, dynamic>            _relatorioData  = {};
  List<ParcelaCreditoModel>       _parcelasCredito = [];
List<PagamentoCreditoModel>     _pagamentosCredito = [];
Map<String, dynamic>            _extractoCliente = {};
List<PedidoModel> _pedidosEmDivida = [];

  PedidoStatus _status       = PedidoStatus.idle;
  String?      _errorMessage;

  // ── Getters ──────────────────────────────────────────────────────────────
  PedidoModel?                   get pedidoActual    => _pedidoActual;
  List<PedidoModel>              get pedidos         => List.unmodifiable(_pedidos);
  List<TipoPagamentoResponseDTO> get tiposPagamento  => List.unmodifiable(_tiposPagamento);
  List<PedidoModel> get pedidosEmDivida => List.unmodifiable(_pedidosEmDivida);
  Map<String, dynamic>           get dashboardData   => Map.unmodifiable(_dashboardData);
  Map<String, dynamic>           get relatorioData   => Map.unmodifiable(_relatorioData);
  List<ParcelaCreditoModel> get parcelasCredito =>
    List.unmodifiable(_parcelasCredito);

List<PagamentoCreditoModel> get pagamentosCredito =>
    List.unmodifiable(_pagamentosCredito);

Map<String, dynamic> get extractoCliente =>
    Map.unmodifiable(_extractoCliente);
  PedidoStatus                   get status         => _status;
  String?                        get errorMessage    => _errorMessage;
  bool                           get isLoading       => _status == PedidoStatus.loading;

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
  // CRIAR PEDIDO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> criarPedido(PedidoRequestModel dto) async {
    final result = await _run(() => _repository.criarPedido(dto));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // ADICIONAR ITEM DE PRODUTO
  // ════════════════════════════════════════════════════════════════════════

Future<PedidoModel?> adicionarItemProduto(
  int idPedido,
  ItemPedidoRequestModel dto,
) async {
  final result = await _run(() => _repository.adicionarItemProduto(
        idPedido,
        ItemPedidoRequestDTO(
          idProduto:  dto.idProduto,
          quantidade: dto.quantidade,
        ),
      ));
  if (result != null) {
    _pedidoActual = result;
    // Recarrega a lista de produtos para reflectir o novo estoque
    await _produtoProvider.listarAtivos();
  }
  return result;
}

  // ════════════════════════════════════════════════════════════════════════
  // ADICIONAR ITEM DE SERVIÇO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> adicionarItemServico(
    int idPedido,
    ItemServicoRequestModel dto,
  ) async {
    final result = await _run(() => _repository.adicionarItemServico(
          idPedido,
          ItemServicoRequestDTO(
            idServico:   dto.idServico,
            quantidade:  dto.quantidade,
            observacoes: dto.observacoes,
          ),
        ));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // EDITAR QUANTIDADE DE ITEM DE PRODUTO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> editarQuantidadeItemProduto(
    int idPedido,
    int idItemPedido,
    int novaQuantidade,
  ) async {
    final result = await _run(() => _repository.editarQuantidadeItemProduto(
          idPedido,
          idItemPedido,
          EditarItemRequestDTO(novaQuantidade: novaQuantidade),
        ));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // EDITAR QUANTIDADE DE ITEM DE SERVIÇO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> editarQuantidadeItemServico(
    int idPedido,
    int idItemServico,
    int novaQuantidade,
  ) async {
    final result = await _run(() => _repository.editarQuantidadeItemServico(
          idPedido,
          idItemServico,
          EditarItemRequestDTO(novaQuantidade: novaQuantidade),
        ));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // ELIMINAR ITEM DE PRODUTO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> eliminarItemProduto(
      int idPedido, int idItemPedido) async {
    final result = await _run(
        () => _repository.eliminarItemProduto(idPedido, idItemPedido));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // ELIMINAR ITEM DE SERVIÇO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> eliminarItemServico(
      int idPedido, int idItemServico) async {
    final result = await _run(
        () => _repository.eliminarItemServico(idPedido, idItemServico));
    if (result != null) _pedidoActual = result;
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // FINALIZAR PEDIDO
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> finalizarPedido(
  int idPedido,
  FinalizarPedidoRequestModel dto,
) async {
  final result = await _run(() => _repository.finalizarPedido(
        idPedido,
        FinalizarPedidoRequestDTO(
          idTipoPagamento:        dto.idTipoPagamento,
          valorPago:              dto.valorPago,
          observacoes:            dto.observacoes,
          idCliente:              dto.idCliente,
          nomeClienteSingular:    dto.nomeClienteSingular,
          apelidoClienteSingular: dto.apelidoClienteSingular,
        ),
      ));
  // Após finalizar, limpa o pedido activo no provider
  _pedidoActual = null;
  notifyListeners();
  return result;
}

  // ════════════════════════════════════════════════════════════════════════
  // CANCELAR PEDIDO
  // ════════════════════════════════════════════════════════════════════════

Future<bool> cancelarPedido(
    int idPedido,
    CancelamentoPedidoRequestModel dto,
  ) async {
    await _run(() => _repository.cancelarPedido(
          idPedido,
          CancelamentoPedidoRequestDTO(
            idUsuarioCancelou: dto.idUsuarioCancelou,
            motivo:            dto.motivo,
          ),
        ));
    if (_status == PedidoStatus.success) {
      _pedidoActual = null;          // ← limpa sempre, sem condição
      notifyListeners();
      PedidoAtivoController.instance.limpar();
    }
    return _status == PedidoStatus.success;
  }
  // ════════════════════════════════════════════════════════════════════════
  // CONSULTAS
  // ════════════════════════════════════════════════════════════════════════

  Future<PedidoModel?> buscarPorId(int idPedido) async {
    final result = await _run(() => _repository.buscarPorId(idPedido));
    if (result != null) _pedidoActual = result;
    return result;
  }

  Future<void> listarPorUsuario(int idUsuario) async {
    final result = await _run(() => _repository.listarPorUsuario(idUsuario));
    if (result != null) _pedidos = result;
  }

  Future<void> listarPorStatus(String status) async {
    final result = await _run(() => _repository.listarPorStatus(status));
    if (result != null) _pedidos = result;
  }

  Future<void> listarPorUsuarioEStatus(int idUsuario, String status) async {
    final result = await _run(
        () => _repository.listarPorUsuarioEStatus(idUsuario, status));
    if (result != null) _pedidos = result;
  }

  Future<void> carregarTiposPagamento() async {
    final result = await _run(() => _repository.listarTiposPagamento());
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
        _repository.relatorioPedidosUsuario(idUsuario, dataInicio: dataInicio));
    if (result != null) _relatorioData = result;
  }

  Future<void> carregarDashboard(
    int idUsuario, {
    required DateTime dataInicio,
  }) async {
    final result = await _run(
        () => _repository.dashboardUsuario(idUsuario, dataInicio: dataInicio));
    if (result != null) _dashboardData = result;
  }

  // ════════════════════════════════════════════════════════════════════════
  // UTILITÁRIOS
  // ════════════════════════════════════════════════════════════════════════

void definirPedidoActual(PedidoModel pedido) {
  _pedidoActual = pedido;
  notifyListeners();
}

  void limparPedidoActual() {
    _pedidoActual = null;
    notifyListeners();
  }

void limparPedidos() {
  _pedidos = [];
  _pedidosEmDivida = [];  
  _parcelasCredito = [];
  _pagamentosCredito = [];
  _extractoCliente = {};
  notifyListeners();
}

  void limparErro() {
    _errorMessage = null;
    _status = PedidoStatus.idle;
    notifyListeners();
  }

Future<PedidoModel?> declararCredito(
  int idPedido,
  DeclararCreditoRequestModel dto,
) async {
  final result = await _run(() => _repository.declararCredito(idPedido, dto));

  if (result != null) {
    // Remove da lista de pedidos abertos
    _pedidos.removeWhere((p) => p.idPedido == result.idPedido);

    // Atualiza a lista de dívidas
    _pedidosEmDivida.removeWhere((p) => p.idPedido == result.idPedido);
    _pedidosEmDivida.insert(0, result);

    // Depois de confirmar crédito, o pedido NÃO deve continuar activo.
    _pedidoActual = null;
    PedidoAtivoController.instance.limpar();

    notifyListeners();
  }

  return result;
}
Future<List<ParcelaCreditoModel>> criarParcelas(
  int idPedido,
  CriarParcelasRequestModel dto,
) async {
  final result = await _run(() => _repository.criarParcelas(idPedido, dto));

  if (result != null) {
    _parcelasCredito = result;
    notifyListeners();
    return result;
  }

  return [];
}

Future<PagamentoCreditoModel?> registarPagamentoCredito(
  int idPedido,
  RegistarPagamentoCreditoRequestModel dto,
) async {
  final result = await _run(
    () => _repository.registarPagamentoCredito(idPedido, dto),
  );

  if (result != null) {
    _pagamentosCredito.insert(0, result);
    _pedidoActual = null;

    // ── NOVO: mantém pedidosEmDivida sincronizada, sem precisar de recarregar ──
    final atualizado = await _repository.buscarPorId(idPedido);
    if (atualizado != null) {
      final idx = _pedidosEmDivida.indexWhere((p) => p.idPedido == idPedido);
      if (idx != -1) {
        _pedidosEmDivida[idx] = atualizado;
      } else {
        _pedidosEmDivida.insert(0, atualizado);
      }
    }

    notifyListeners();
  }

  return result;
}

Future<void> carregarParcelas(int idPedido) async {
  final result = await _run(() => _repository.listarParcelas(idPedido));

  if (result != null) {
    _parcelasCredito = result;
  }
}

Future<void> carregarPagamentosCredito(int idPedido) async {
  final result =
      await _run(() => _repository.listarPagamentosCredito(idPedido));

  if (result != null) {
    _pagamentosCredito = result;
  }
}

Future<void> listarEmDivida() async {
  _errorMessage = null; // limpa erro de chamadas anteriores
  final result = await _run(() => _repository.listarEmDivida());
  if (result != null) {
    _pedidosEmDivida = result;
  }
}

Future<void> carregarExtractoCliente(int idCliente) async {
  final result = await _run(() => _repository.extractoCliente(idCliente));

  if (result != null) {
    _extractoCliente = result;
  }
}





  @override
  void dispose() {
    super.dispose();
  }
}
