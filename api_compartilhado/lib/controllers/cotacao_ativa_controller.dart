// lib/controllers/cotacao_ativa_controller.dart
//
// Mantém a cotação activa (em montagem) durante a sessão.
// Qualquer widget pode escutar via ValueListenableBuilder.

import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_compartilhado.dart'; // CotacaoModel

class CotacaoAtivaController {
  CotacaoAtivaController._();
  static final CotacaoAtivaController instance = CotacaoAtivaController._();

  final ValueNotifier<CotacaoModel?> cotacaoAtiva = ValueNotifier(null);

  /// Define (ou substitui) a cotação activa.
  void definir(CotacaoModel cotacao) => cotacaoAtiva.value = cotacao;

  /// Limpa a cotação activa (após converter ou cancelar).
  void limpar() => cotacaoAtiva.value = null;

  void dispose() => cotacaoAtiva.dispose();
}