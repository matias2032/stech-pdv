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

class LinhaDespesaExtrato {
  final DateTime dataDespesa;
  final String descricao;
  final String nomeFornecedor;
  final String? nuitFornecedor;
  final double valorGasto;

  const LinhaDespesaExtrato({
    required this.dataDespesa,
    required this.descricao,
    required this.nomeFornecedor,
    this.nuitFornecedor,
    required this.valorGasto,
  });
}

/// Resultado completo de um extracto gerado.
class ExtratoModel {
  final List<LinhaExtrato> linhas;
  final List<LinhaDespesaExtrato> despesas;

  final DateTime dataInicio;
  final DateTime dataFim;
  final String labelPeriodo;

  const ExtratoModel({
    required this.linhas,
    this.despesas = const [],
    required this.dataInicio,
    required this.dataFim,
    required this.labelPeriodo,
  });

  int get totalDocumentos => linhas.length;

  int get totalDespesasRegistadas => despesas.length;

  double get somaTotal =>
      linhas.fold(0.0, (acc, l) => acc + l.valorTotal);

  double get somaDespesas =>
      despesas.fold(0.0, (acc, d) => acc + d.valorGasto);

  double get resultadoLiquido => somaTotal - somaDespesas;
}