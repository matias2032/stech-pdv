class DespesaModel {
  final int? idDespesa;
  final int? idFornecedor;
  final String? nomeFornecedor;
  final String? nuitFornecedor;
  final String descricao;
  final double valorGasto;
  final DateTime? dataDespesa;
  final bool deleted;
  final String? syncStatus;
  final int? version;

  const DespesaModel({
    this.idDespesa,
    this.idFornecedor,
    this.nomeFornecedor,
    this.nuitFornecedor,
    required this.descricao,
    required this.valorGasto,
    this.dataDespesa,
    this.deleted = false,
    this.syncStatus,
    this.version,
  });

  factory DespesaModel.fromJson(Map<String, dynamic> json) {
    return DespesaModel(
      idDespesa: _parseIntOpt(json['idDespesa']),
      idFornecedor: _parseIntOpt(json['idFornecedor']),
      nomeFornecedor: _parseStringOpt(json['nomeFornecedor']),
      nuitFornecedor: _parseStringOpt(json['nuitFornecedor']),
      descricao: json['descricao']?.toString() ?? '',
      valorGasto: _parseDouble(json['valorGasto']),
      dataDespesa: _parseDateOpt(json['dataDespesa']),
      deleted: _parseBool(json['deleted']),
      syncStatus: _parseStringOpt(json['syncStatus']),
      version: _parseIntOpt(json['version']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idFornecedor != null) 'idFornecedor': idFornecedor,
      'descricao': descricao.trim(),
      'valorGasto': valorGasto,
    };
  }

  Map<String, dynamic> toLocalDb() {
    return {
      if (idDespesa != null) 'id': idDespesa,
      'id_fornecedor': idFornecedor,
      'nome_fornecedor': nomeFornecedor,
      'nuit_fornecedor': nuitFornecedor,
      'descricao': descricao.trim(),
      'valor_gasto': valorGasto,
      'data_despesa': dataDespesa?.toIso8601String(),
      'deleted': deleted ? 1 : 0,
      'sync_status': syncStatus ?? 'synced',
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  DespesaModel copyWith({
    int? idDespesa,
    int? idFornecedor,
    String? nomeFornecedor,
    String? nuitFornecedor,
    String? descricao,
    double? valorGasto,
    DateTime? dataDespesa,
    bool? deleted,
    String? syncStatus,
    int? version,
  }) {
    return DespesaModel(
      idDespesa: idDespesa ?? this.idDespesa,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      nomeFornecedor: nomeFornecedor ?? this.nomeFornecedor,
      nuitFornecedor: nuitFornecedor ?? this.nuitFornecedor,
      descricao: descricao ?? this.descricao,
      valorGasto: valorGasto ?? this.valorGasto,
      dataDespesa: dataDespesa ?? this.dataDespesa,
      deleted: deleted ?? this.deleted,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
    );
  }

  bool get descricaoValida => descricao.trim().isNotEmpty;
  bool get valorValido => valorGasto > 0;

  static int? _parseIntOpt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  static String? _parseStringOpt(dynamic value) {
    if (value == null) return null;
    final texto = value.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  static DateTime? _parseDateOpt(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value == 1;
    return value.toString().toLowerCase() == 'true';
  }
}