import 'package:intl/intl.dart';

/// Representa uma linha do extracto (1 documento fiscal).
class LinhaExtrato {
  final DateTime dataEmissao;
  final String numeroDocumento;
  final String nomeEmpresa;
  final String? nuit;
  final double valorTotal;

  const LinhaExtrato({
    required this.dataEmissao,
    required this.numeroDocumento,
    required this.nomeEmpresa,
    this.nuit,
    required this.valorTotal,
  });
}

/// Resultado completo de um extracto gerado.
class ExtratoModel {
  final List<LinhaExtrato> linhas;
  final DateTime dataInicio;
  final DateTime dataFim;
  final String labelPeriodo;

  const ExtratoModel({
    required this.linhas,
    required this.dataInicio,
    required this.dataFim,
    required this.labelPeriodo,
  });

  int get totalDocumentos => linhas.length;

  double get somaTotal =>
      linhas.fold(0.0, (acc, l) => acc + l.valorTotal);
}