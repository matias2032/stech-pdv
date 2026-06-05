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

    factory DocumentoFiscalModel.fromLocalDb(Map<String, dynamic> row) =>
      DocumentoFiscalModel(
        id:        row['id']         as int,
        tipoDocumento: TipoDocumentoModel(
          id:      row['id_tipo_doc'] as int,
          codigo:  row['tipo_codigo'] as String? ?? '',
          nome:    row['tipo_nome']   as String? ?? '',
          prefixo: row['tipo_prefixo'] as String? ?? '',
        ),
        idPedido:       row['id_pedido']   as int,
        referencia:     (row['referencia'] as String?) ?? '',
        numeroSeq:      (row['numero_seq'] as int?) ?? 0,
        ano:            (row['ano']        as int?) ?? 0,
        codigoAt:       (row['codigo_at']  as String?) ?? '',
        idUsuario:      row['id_usuario']  as int,
        nomeUsuario:    (row['nome_usuario'] as String?) ?? '',
        emitidoEm:      DateTime.parse(row['emitido_em'] as String),
        anulado:        (row['anulado']    as int?) == 1,
        motivoAnulacao: row['motivo_anulacao'] as String?,
      );

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

        Map<String, dynamic> toLocalDb() => {
        'id':              id,
        'id_tipo_doc':     tipoDocumento.id,
        'tipo_codigo':     tipoDocumento.codigo,
        'tipo_nome':       tipoDocumento.nome,
        'tipo_prefixo':    tipoDocumento.prefixo,
        'id_pedido':       idPedido,
        'referencia':      referencia,
        'numero_seq':      numeroSeq,
        'ano':             ano,
        'codigo_at':       codigoAt,
        'id_usuario':      idUsuario,
        'nome_usuario':    nomeUsuario,
        'emitido_em':      emitidoEm.toIso8601String(),
        'anulado':         anulado ? 1 : 0,
        'motivo_anulacao': motivoAnulacao,
        'sync_status':     'synced',
        'updated_at':      DateTime.now().toIso8601String(),
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