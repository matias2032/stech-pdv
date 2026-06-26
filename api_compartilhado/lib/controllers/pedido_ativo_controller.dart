// lib/controllers/pedido_ativo_controller.dart

import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

class PedidoAtivoController {
  PedidoAtivoController._();

  static final PedidoAtivoController instance = PedidoAtivoController._();

  final ValueNotifier<PedidoModel?> pedidoAtivo = ValueNotifier<PedidoModel?>(null);

  // Quando for edição de crédito, os itens já existentes ficam bloqueados.
  final ValueNotifier<Set<int>> itensProdutoBloqueados =
      ValueNotifier<Set<int>>(<int>{});

  final ValueNotifier<Set<int>> itensServicoBloqueados =
      ValueNotifier<Set<int>>(<int>{});

  bool _edicaoCredito = false;

  bool get edicaoCredito => _edicaoCredito;

  void definir(PedidoModel pedido) {
    _edicaoCredito = false;
    itensProdutoBloqueados.value = <int>{};
    itensServicoBloqueados.value = <int>{};
    pedidoAtivo.value = pedido;
  }

  void definirEdicaoCredito(PedidoModel pedido) {
    _edicaoCredito = true;

    itensProdutoBloqueados.value = pedido.itensProduto
        .map((i) => i.idItemPedido)
        .where((id) => id > 0)
        .toSet();

    itensServicoBloqueados.value = pedido.itensServico
        .map((i) => i.idItemServico)
        .where((id) => id > 0)
        .toSet();

    pedidoAtivo.value = pedido;
  }

  bool produtoEstaBloqueado(int idItemPedido) {
    return _edicaoCredito &&
        itensProdutoBloqueados.value.contains(idItemPedido);
  }

  bool servicoEstaBloqueado(int idItemServico) {
    return _edicaoCredito &&
        itensServicoBloqueados.value.contains(idItemServico);
  }

  void limpar() {
    _edicaoCredito = false;
    itensProdutoBloqueados.value = <int>{};
    itensServicoBloqueados.value = <int>{};
    pedidoAtivo.value = null;
  }

  void dispose() {
    pedidoAtivo.dispose();
    itensProdutoBloqueados.dispose();
    itensServicoBloqueados.dispose();
  }
}