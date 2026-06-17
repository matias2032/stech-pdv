// lib/controllers/pedido_ativo_controller.dart
//
// Mantém o pedido activo (em aberto) durante a sessão.
// Qualquer widget pode escutar via ValueListenableBuilder.

import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_compartilhado.dart'; // PedidoModel

class PedidoAtivoController {
  PedidoAtivoController._();
  static final PedidoAtivoController instance = PedidoAtivoController._();

  final ValueNotifier<PedidoModel?> pedidoAtivo = ValueNotifier(null);

  /// Define (ou substitui) o pedido activo.
  void definir(PedidoModel pedido) => pedidoAtivo.value = pedido;

  /// Limpa o pedido activo (após finalizar ou cancelar).
  void limpar() => pedidoAtivo.value = null;

  void dispose() => pedidoAtivo.dispose();
}

