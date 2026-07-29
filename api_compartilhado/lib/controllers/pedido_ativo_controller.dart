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
    // Nunca reactivar um pedido que o backend já encerrou (finalizado,
    // cancelado, ou crédito já liquidado). Evita que a UI continue a
    // oferecer "Adicionar ao <referência>" para um pedido fechado.
    if (!pedido.podeReceberNovosItens) {
      limpar();
      return;
    }

    _edicaoCredito = false;
    itensProdutoBloqueados.value = <int>{};
    itensServicoBloqueados.value = <int>{};
    pedidoAtivo.value = pedido;
  }

  void definirEdicaoCredito(PedidoModel pedido) {
    // Edição de crédito só faz sentido enquanto o pedido continuar
    // crédito/dívida em aberto.
    if (!(pedido.ehCredito || pedido.estaEmDivida)) {
      limpar();
      return;
    }

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

  void actualizarPedidoMantendoBloqueios(PedidoModel pedido) {
    // Se o pedido deixou de poder receber itens (ex.: foi encerrado por
    // uma devolução/nota de crédito a meio da edição), limpa em vez de
    // manter activo.
    if (!pedido.podeReceberNovosItens) {
      limpar();
      return;
    }
    pedidoAtivo.value = pedido;
  }

  /// Limpa o pedido activo SE for o mesmo [idPedido]. Deve ser chamado
  /// sempre que o backend encerrar um pedido (finalizar, cancelar,
  /// devolução/nota de crédito, crédito liquidado).
  void invalidarSeIdCorresponder(int idPedido) {
    if (pedidoAtivo.value?.idPedido == idPedido) {
      limpar();
    }
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