/// Espelho do ServicoResponseDTO / Servico entity Java.
class ServicoModel {
  final int idServico;
  final String nomeServico;
  final String? descricao;
  final double precoUnitario;
  final String unidade; // página, folha, unidade…
  final bool ativo;

  const ServicoModel({
    required this.idServico,
    required this.nomeServico,
    this.descricao,
    required this.precoUnitario,
    required this.unidade,
    required this.ativo,
  });

  factory ServicoModel.fromJson(Map<String, dynamic> json) {
    return ServicoModel(
      idServico: json['idServico'] as int,
      nomeServico: json['nomeServico'] as String,
      descricao: json['descricao'] as String?,
      precoUnitario: (json['precoUnitario'] as num).toDouble(),
      unidade: json['unidade'] as String? ?? 'página',
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'idServico': idServico,
        'nomeServico': nomeServico,
        'descricao': descricao,
        'precoUnitario': precoUnitario,
        'unidade': unidade,
        'ativo': ativo,
      };

  ServicoModel copyWith({
    int? idServico,
    String? nomeServico,
    String? descricao,
    double? precoUnitario,
    String? unidade,
    bool? ativo,
  }) {
    return ServicoModel(
      idServico: idServico ?? this.idServico,
      nomeServico: nomeServico ?? this.nomeServico,
      descricao: descricao ?? this.descricao,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      unidade: unidade ?? this.unidade,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  String toString() =>
      'ServicoModel(id: $idServico, nome: $nomeServico, ativo: $ativo)';
}

// ─── Request DTO ─────────────────────────────────────────────────────────────

/// Espelho do ServicoRequestDTO Java.
class ServicoRequestModel {
  final String nomeServico;
  final String? descricao;
  final double precoUnitario;
  final String unidade;

  const ServicoRequestModel({
    required this.nomeServico,
    this.descricao,
    required this.precoUnitario,
    required this.unidade,
  });

  Map<String, dynamic> toJson() => {
        'nomeServico': nomeServico,
        'descricao': descricao,
        'precoUnitario': precoUnitario,
        'unidade': unidade,
      };
}