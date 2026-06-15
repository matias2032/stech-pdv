// lib/controllers/cotacao_ativa_controller.dart


import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_compartilhado.dart'; // CotacaoModel

class CotacaoAtivaController {
  CotacaoAtivaController._();
  static final CotacaoAtivaController instance = CotacaoAtivaController._();

  final ValueNotifier<CotacaoModel?> cotacaoAtiva = ValueNotifier(null);

  void definir(CotacaoModel cotacao) {
    // ← só aceita cotações ABERTAS
    if (cotacao.estaAberta) {
      cotacaoAtiva.value = cotacao;
    } else {
      cotacaoAtiva.value = null;
    }
  }

  void limpar() => cotacaoAtiva.value = null;

  /// Limpa automaticamente se a cotação já não estiver aberta.
  void limparSeNaoAberta() {
    final atual = cotacaoAtiva.value;
    if (atual != null && !atual.estaAberta) {
      cotacaoAtiva.value = null;
    }
  }

  void dispose() => cotacaoAtiva.dispose();
}