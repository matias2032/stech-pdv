class TipoDespesaModel {
  final int? idTipoDespesa;
  final String nomeDespesa;
  final String? descricao;
  final bool deleted;
  final String? syncStatus;
  final int? version;

  const TipoDespesaModel({
    this.idTipoDespesa,
    required this.nomeDespesa,
    this.descricao,
    this.deleted = false,
    this.syncStatus,
    this.version,
  });

  factory TipoDespesaModel.fromJson(Map<String, dynamic> json) {
    return TipoDespesaModel(
      idTipoDespesa: _parseIntOpt(json['idTipoDespesa'] ?? json['id']),
      nomeDespesa: json['nomeDespesa']?.toString() ??
          json['nome_despesa']?.toString() ??
          '',
      descricao: _parseStringOpt(json['descricao']),
      deleted: _parseBool(json['deleted']),
      syncStatus: _parseStringOpt(json['syncStatus'] ?? json['sync_status']),
      version: _parseIntOpt(json['version']),
    );
  }

  Map<String, dynamic> toLocalDb() {
    return {
      if (idTipoDespesa != null) 'id': idTipoDespesa,
      'nome_despesa': nomeDespesa.trim(),
      'descricao': descricao,
      'deleted': deleted ? 1 : 0,
      'sync_status': syncStatus ?? 'synced',
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static int? _parseIntOpt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static String? _parseStringOpt(dynamic value) {
    if (value == null) return null;
    final texto = value.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value == 1;
    return value.toString().toLowerCase() == 'true';
  }
}

class DespesaModel {
  final int? idDespesa;
  final int? idFornecedor;
  final String? nomeFornecedor;
  final String? nuitFornecedor;
  final String descricao;
  final double valorGasto;
  final DateTime? dataDespesa;
  final String? motivoExclusao;
  final int? idTipoDespesa;
final String? nomeTipoDespesa;
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
    this.motivoExclusao,
    this.idTipoDespesa,
this.nomeTipoDespesa,
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
      motivoExclusao: _parseStringOpt(
  json['motivoExclusao'] ?? json['motivo_exclusao'],
),
idTipoDespesa: _parseIntOpt(json['idTipoDespesa']),
nomeTipoDespesa: _parseStringOpt(json['nomeTipoDespesa']),
      deleted: _parseBool(json['deleted']),
      syncStatus: _parseStringOpt(json['syncStatus']),
      version: _parseIntOpt(json['version']),
    );
  }

Map<String, dynamic> toJson() {
  return {
    if (idFornecedor != null) 'idFornecedor': idFornecedor,
    if (idTipoDespesa != null) 'idTipoDespesa': idTipoDespesa,
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
      'motivo_exclusao': motivoExclusao,
      'id_tipo_despesa': idTipoDespesa,
'nome_tipo_despesa': nomeTipoDespesa,
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
    String? motivoExclusao,
    int? idTipoDespesa,
String? nomeTipoDespesa,
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
      motivoExclusao: motivoExclusao ?? this.motivoExclusao,
      idTipoDespesa: idTipoDespesa ?? this.idTipoDespesa,
nomeTipoDespesa: nomeTipoDespesa ?? this.nomeTipoDespesa,
      deleted: deleted ?? this.deleted,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
    );
  }

  bool get descricaoValida => descricao.trim().isNotEmpty;
  bool get valorValido => valorGasto > 0;
  bool get tipoValido => idTipoDespesa != null && idTipoDespesa! > 0;

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