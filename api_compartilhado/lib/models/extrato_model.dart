import 'package:intl/intl.dart';

/// Representa uma linha do extracto (1 documento fiscal).
class LinhaExtrato {
  final DateTime dataEmissao;
  final String numeroDocumento;
  final String nomeEmpresa;
  final String? nuit;
  final double valorTotal;
  final String estado;

  /// true quando esta linha representa o ajuste (Nota de Crédito/Débito)
  /// de uma factura, e não a própria factura. Usado para destacar a linha
  /// com cor própria no extracto documental do cliente.
  final bool isAjusteNotaRetificativa;

  const LinhaExtrato({
    required this.dataEmissao,
    required this.numeroDocumento,
    required this.nomeEmpresa,
    this.nuit,
    required this.valorTotal,
    this.estado = '-',
    this.isAjusteNotaRetificativa = false,
  });
}

class LinhaDespesaExtrato {
  final DateTime dataDespesa;
  final String descricao;
  final String nomeFornecedor;
  final String? nuitFornecedor;
  final double valorGasto;

  final int? idTipoDespesa;
  final String? nomeTipoDespesa;

  const LinhaDespesaExtrato({
    required this.dataDespesa,
    required this.descricao,
    required this.nomeFornecedor,
    this.nuitFornecedor,
    required this.valorGasto,
    this.idTipoDespesa,
    this.nomeTipoDespesa,
  });
}

class SimulacaoApuramentoIvaModel {
  final double campo1;
  final double campo2;
  final double campo3;
  final double campo4;
  final double campo5;
  final double campo6;
  final double campo7;
  final double campo8;
  final double campo9;
  final double campo10;
  final double campo11;
  final double campo12;
  final double campo13;
  final double campo14;
  final double campo15;
  final double campo16;
  final double campo17;
  final double campo18;
  final double campo19;
  final double campo20;

  const SimulacaoApuramentoIvaModel({
    required this.campo1,
    required this.campo2,
    required this.campo3,
    required this.campo4,
    required this.campo5,
    required this.campo6,
    required this.campo7,
    required this.campo8,
    required this.campo9,
    required this.campo10,
    required this.campo11,
    required this.campo12,
    required this.campo13,
    required this.campo14,
    required this.campo15,
    required this.campo16,
    required this.campo17,
    required this.campo18,
    required this.campo19,
    required this.campo20,
  });

  factory SimulacaoApuramentoIvaModel.fromExtrato(
    ExtratoModel extrato, {
    double campo19 = 0,
  }) {
    final totalPrestacao = extrato.somaTotal;

    final campo1 = _valorSemIva(totalPrestacao);
    final campo2 = totalPrestacao - campo1;

    const campo3 = 0.0;
    const campo4 = 0.0;
    const campo5 = 0.0;
    const campo6 = 0.0;
    const campo7 = 0.0;

    final totalImobilizado = _totalDespesaTipo(extrato, 'Imobilizado');
    final totalExistencias = _totalDespesaTipo(extrato, 'Existências');
    final totalBensServicos = _totalDespesaTipo(extrato, 'Bens e Serviços');
    final totalImportacao = _totalDespesaTipo(extrato, 'Importação');

    final campo8 = _ivaIncluido(totalImobilizado);
    final campo9 = _ivaIncluido(totalExistencias);
    final campo10 = _ivaIncluido(totalBensServicos);
    final campo11 = _ivaIncluido(totalImportacao);

    const campo12 = 0.0;
    const campo13 = 0.0;

    final campo14 = campo1 + campo3 + campo5 + campo6 + campo7;
    final campo15 = campo8 + campo9 + campo10 + campo11 + campo12;
    final campo16 = campo2 + campo4 + campo13;

    final diferenca = campo16 - campo15;

    final campo17 = diferenca > 0 ? diferenca : 0.0;
    final campo18 = diferenca < 0 ? diferenca.abs() : 0.0;

    final campo19Normalizado = campo19 < 0 ? 0.0 : campo19;

final campo20 = campo17 > 0
    ? campo17 - campo19Normalizado
    : campo18 > 0
        ? campo18 + campo19Normalizado
        : 0.0;

    return SimulacaoApuramentoIvaModel(
      campo1: campo1,
      campo2: campo2,
      campo3: campo3,
      campo4: campo4,
      campo5: campo5,
      campo6: campo6,
      campo7: campo7,
      campo8: campo8,
      campo9: campo9,
      campo10: campo10,
      campo11: campo11,
      campo12: campo12,
      campo13: campo13,
      campo14: campo14,
      campo15: campo15,
      campo16: campo16,
      campo17: campo17,
      campo18: campo18,
      campo19: campo19Normalizado,
      campo20: campo20,
    );
  }

  SimulacaoApuramentoIvaModel recalcularComCampo19(double novoCampo19) {
  final campo19Normalizado = novoCampo19 < 0 ? 0.0 : novoCampo19;

  final novoCampo20 = campo17 > 0
      ? campo17 - campo19Normalizado
      : campo18 > 0
          ? campo18 + campo19Normalizado
          : 0.0;

  return SimulacaoApuramentoIvaModel(
    campo1: campo1,
    campo2: campo2,
    campo3: campo3,
    campo4: campo4,
    campo5: campo5,
    campo6: campo6,
    campo7: campo7,
    campo8: campo8,
    campo9: campo9,
    campo10: campo10,
    campo11: campo11,
    campo12: campo12,
    campo13: campo13,
    campo14: campo14,
    campo15: campo15,
    campo16: campo16,
    campo17: campo17,
    campo18: campo18,
    campo19: campo19Normalizado,
    campo20: novoCampo20,
  );
}

  static double _valorSemIva(double valorComIva) {
    if (valorComIva <= 0) return 0.0;
    return valorComIva / 1.16;
  }

  static double _ivaIncluido(double valorComIva) {
    if (valorComIva <= 0) return 0.0;
    return valorComIva - _valorSemIva(valorComIva);
  }

  static double _totalDespesaTipo(ExtratoModel extrato, String tipo) {
    final tipoNormalizado = tipo.trim().toLowerCase();

    return extrato.despesas
        .where((d) =>
            (d.nomeTipoDespesa ?? '').trim().toLowerCase() ==
            tipoNormalizado)
        .fold<double>(0.0, (acc, d) => acc + d.valorGasto);
  }
}

/// Resultado completo de um extracto gerado.
class ExtratoModel {
  final List<LinhaExtrato> linhas;
  final List<LinhaDespesaExtrato> despesas;

  final DateTime dataInicio;
  final DateTime dataFim;
  final String labelPeriodo;

  final SimulacaoApuramentoIvaModel? apuramentoIva;

  const ExtratoModel({
    required this.linhas,
    this.despesas = const [],
    required this.dataInicio,
    required this.dataFim,
    required this.labelPeriodo,
    this.apuramentoIva,
  });

  int get totalDocumentos => linhas.length;

  int get totalDespesasRegistadas => despesas.length;

  double get somaTotal =>
      linhas.fold(0.0, (acc, l) => acc + l.valorTotal);

  double get somaDespesas =>
      despesas.fold(0.0, (acc, d) => acc + d.valorGasto);

  double get resultadoLiquido => somaTotal - somaDespesas;

  ExtratoModel copyWith({
    List<LinhaExtrato>? linhas,
    List<LinhaDespesaExtrato>? despesas,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? labelPeriodo,
    SimulacaoApuramentoIvaModel? apuramentoIva,
  }) {
    return ExtratoModel(
      linhas: linhas ?? this.linhas,
      despesas: despesas ?? this.despesas,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      labelPeriodo: labelPeriodo ?? this.labelPeriodo,
      apuramentoIva: apuramentoIva ?? this.apuramentoIva,
    );
  }
}