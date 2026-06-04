// lib/models/documento_fiscal_model.dart

class TipoDocumentoModel {
  final int id;
  final String codigo;
  final String nome;
  final String prefixo;

  const TipoDocumentoModel({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.prefixo,
  });

  factory TipoDocumentoModel.fromJson(Map<String, dynamic> json) {
    return TipoDocumentoModel(
      id: json['id'] as int,
      codigo: json['codigo'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      prefixo: json['prefixo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'nome': nome,
        'prefixo': prefixo,
      };

  TipoDocumentoModel copyWith({
    int? id,
    String? codigo,
    String? nome,
    String? prefixo,
  }) {
    return TipoDocumentoModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      prefixo: prefixo ?? this.prefixo,
    );
  }

  @override
  String toString() => '$prefixo — $nome';
}

// ─────────────────────────────────────────────────────────────────────────────

class DocumentoFiscalModel {
  final int id;
  final TipoDocumentoModel tipoDocumento;
  final int idPedido;
  final String referencia;
  final int numeroSeq;
  final int ano;
  final String codigoAt;
  final int idUsuario;
  final String nomeUsuario;
  final DateTime emitidoEm;
  final bool anulado;
  final String? motivoAnulacao;

  const DocumentoFiscalModel({
    required this.id,
    required this.tipoDocumento,
    required this.idPedido,
    required this.referencia,
    required this.numeroSeq,
    required this.ano,
    required this.codigoAt,
    required this.idUsuario,
    required this.nomeUsuario,
    required this.emitidoEm,
    required this.anulado,
    this.motivoAnulacao,
  });

  factory DocumentoFiscalModel.fromJson(Map<String, dynamic> json) {
    return DocumentoFiscalModel(
      id: json['id'] as int,
      tipoDocumento: TipoDocumentoModel.fromJson(
          json['tipoDocumento'] as Map<String, dynamic>),
      idPedido: json['idPedido'] as int,
      referencia: json['referencia'] as String? ?? '',
      numeroSeq: json['numeroSeq'] as int,
      ano: json['ano'] as int,
      codigoAt: json['codigoAt'] as String? ?? '',
      idUsuario: json['idUsuario'] as int,
      nomeUsuario: json['nomeUsuario'] as String? ?? '',
      emitidoEm: DateTime.parse(json['emitidoEm'] as String),
      anulado: json['anulado'] as bool? ?? false,
      motivoAnulacao: json['motivoAnulacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipoDocumento': tipoDocumento.toJson(),
        'idPedido': idPedido,
        'referencia': referencia,
        'numeroSeq': numeroSeq,
        'ano': ano,
        'codigoAt': codigoAt,
        'idUsuario': idUsuario,
        'nomeUsuario': nomeUsuario,
        'emitidoEm': emitidoEm.toIso8601String(),
        'anulado': anulado,
        'motivoAnulacao': motivoAnulacao,
      };

  DocumentoFiscalModel copyWith({
    int? id,
    TipoDocumentoModel? tipoDocumento,
    int? idPedido,
    String? referencia,
    int? numeroSeq,
    int? ano,
    String? codigoAt,
    int? idUsuario,
    String? nomeUsuario,
    DateTime? emitidoEm,
    bool? anulado,
    String? motivoAnulacao,
  }) {
    return DocumentoFiscalModel(
      id: id ?? this.id,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      idPedido: idPedido ?? this.idPedido,
      referencia: referencia ?? this.referencia,
      numeroSeq: numeroSeq ?? this.numeroSeq,
      ano: ano ?? this.ano,
      codigoAt: codigoAt ?? this.codigoAt,
      idUsuario: idUsuario ?? this.idUsuario,
      nomeUsuario: nomeUsuario ?? this.nomeUsuario,
      emitidoEm: emitidoEm ?? this.emitidoEm,
      anulado: anulado ?? this.anulado,
      motivoAnulacao: motivoAnulacao ?? this.motivoAnulacao,
    );
  }

  
}