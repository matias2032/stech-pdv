/// Espelho do ServicoResponseDTO / Servico entity Java.
class ServicoModel {
  final int idServico;
  final String nomeServico;
  final String? descricao;
  final double precoUnitario;
  final String unidade; // página, folha, unidade…
  final bool ativo;
  final String syncStatus;
final String? localId;

bool get isPending  => syncStatus == 'pending';
bool get isSynced   => syncStatus == 'synced';
bool get isConflict => syncStatus == 'conflict';
bool get isOffline  => isPending;

  const ServicoModel({
    required this.idServico,
    required this.nomeServico,
    this.descricao,
    required this.precoUnitario,
    required this.unidade,
    required this.ativo,
      this.syncStatus = 'synced',   // ← novo
  this.localId,    
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
      String? syncStatus,
  String? localId,
  }) {
    return ServicoModel(
      idServico: idServico ?? this.idServico,
      nomeServico: nomeServico ?? this.nomeServico,
      descricao: descricao ?? this.descricao,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      unidade: unidade ?? this.unidade,
      ativo: ativo ?? this.ativo,
        syncStatus: syncStatus ?? this.syncStatus,
  localId:    localId    ?? this.localId,
    );
  }
  factory ServicoModel.fromLocalDb(Map<String, dynamic> row) => ServicoModel(
      idServico:     row['id']             as int,
      nomeServico:   row['nome_servico']   as String,
      descricao:     row['descricao']      as String?,
      precoUnitario: (row['preco_unitario'] as num).toDouble(),
      unidade:       row['unidade']        as String? ?? 'página',
      ativo:         (row['ativo']         as int? ?? 1) == 1,
    );

Map<String, dynamic> toLocalDb() => {
      'id':            idServico,
      'local_id':      null,
      'nome_servico':  nomeServico,
      'descricao':     descricao,
      'preco_unitario': precoUnitario,
      'unidade':       unidade,
      'ativo':         ativo ? 1 : 0,
      'sync_status':   'synced',
      'updated_at':    DateTime.now().toIso8601String(),
    };


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