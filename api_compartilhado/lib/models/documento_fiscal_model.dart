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
  final String? tipoVenda;
  final String? snapshotConteudo;
  final double? valorTotalEmissao;

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
    this.tipoVenda,
    this.snapshotConteudo,
    this.valorTotalEmissao,
  });

  factory DocumentoFiscalModel.fromJson(Map<String, dynamic> json) {
    return DocumentoFiscalModel(
      id: (json['id'] ?? json['id_documento'] ?? 0) as int,
      tipoDocumento: TipoDocumentoModel.fromJson(
        (json['tipoDocumento'] ?? json['tipo_documento']) as Map<String, dynamic>,
      ),
      idPedido: (json['idPedido'] ?? json['id_pedido'] ?? 0) as int,
      referencia: json['referencia'] as String? ?? '',
      numeroSeq: (json['numeroSeq'] ?? json['numero_seq'] ?? 0) as int,
      ano: (json['ano'] ?? DateTime.now().year) as int,
      codigoAt: (json['codigoAt'] ?? json['codigo_at'] ?? '') as String,
      idUsuario: (json['idUsuario'] ?? json['id_usuario'] ?? 0) as int,
      nomeUsuario: (json['nomeUsuario'] ?? json['nome_usuario'] ?? '') as String,
      emitidoEm: json['emitidoEm'] != null
          ? DateTime.parse(json['emitidoEm'] as String)
          : (json['emitido_em'] != null
              ? DateTime.parse(json['emitido_em'] as String)
              : DateTime.now()),
anulado: json['anulado'] as bool? ?? false,
      motivoAnulacao: json['motivoAnulacao'] ?? json['motivo_anulacao'],
      tipoVenda: json['tipoVenda'] ?? json['tipo_venda'],
      snapshotConteudo: json['snapshotConteudo'] ?? json['snapshot_conteudo'],
      valorTotalEmissao: (json['valorTotalEmissao'] ?? json['valor_total_emissao']) != null
          ? ((json['valorTotalEmissao'] ?? json['valor_total_emissao']) as num).toDouble()
          : null,
    );
  }

  factory DocumentoFiscalModel.fromLocalDb(Map<String, dynamic> row) =>
      DocumentoFiscalModel(
        id: row['id'] as int,
        tipoDocumento: TipoDocumentoModel(
          id: row['id_tipo_doc'] as int,
          codigo: row['tipo_codigo'] as String? ?? '',
          nome: row['tipo_nome'] as String? ?? '',
          prefixo: row['tipo_prefixo'] as String? ?? '',
        ),
        idPedido: row['id_pedido'] as int,
        referencia: (row['referencia'] as String?) ?? '',
        numeroSeq: (row['numero_seq'] as int?) ?? 0,
        ano: (row['ano'] as int?) ?? 0,
        codigoAt: (row['codigo_at'] as String?) ?? '',
        idUsuario: row['id_usuario'] as int,
        nomeUsuario: (row['nome_usuario'] as String?) ?? '',
        emitidoEm: DateTime.parse(row['emitido_em'] as String),
anulado: (row['anulado'] as int?) == 1,
        motivoAnulacao: row['motivo_anulacao'] as String?,
        tipoVenda: row['tipo_venda'] as String?, // ✅ Adicionado no BD Local
        snapshotConteudo: row['snapshot_conteudo'] as String?,
        valorTotalEmissao: (row['valor_total_emissao'] as num?)?.toDouble(),
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
        'tipoVenda': tipoVenda,
        'snapshotConteudo': snapshotConteudo,
        'valorTotalEmissao': valorTotalEmissao,
      };

Map<String, dynamic> toLocalDb() => {
        'id': id,
        'id_tipo_doc': tipoDocumento.id,
        'tipo_codigo': tipoDocumento.codigo,
        'tipo_nome': tipoDocumento.nome,
        'tipo_prefixo': tipoDocumento.prefixo,
        'id_pedido': idPedido,
        'referencia': referencia,
        'numero_seq': numeroSeq,
        'ano': ano,
        'codigo_at': codigoAt,
        'id_usuario': idUsuario,
        'nome_usuario': nomeUsuario,
        'emitido_em': emitidoEm.toIso8601String(),
        'anulado': anulado ? 1 : 0,
        'motivo_anulacao': motivoAnulacao,
        'tipo_venda': tipoVenda, // ✅ Adicionado no BD Local
        'snapshot_conteudo': snapshotConteudo,
        'valor_total_emissao': valorTotalEmissao,
        'sync_status': 'synced',
        'updated_at': DateTime.now().toIso8601String(),
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
    String? tipoVenda,
    String? snapshotConteudo,
    double? valorTotalEmissao,
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
      tipoVenda: tipoVenda ?? this.tipoVenda,
      snapshotConteudo: snapshotConteudo ?? this.snapshotConteudo,
      valorTotalEmissao: valorTotalEmissao ?? this.valorTotalEmissao,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Resposta da emissão de uma Nota de Crédito (NCR) ou Nota de Débito (NDB).
/// Reflecte DocumentoFiscalResponse.NotaRetificativaResponse do backend.
class NotaRetificativaResponseModel {
  final DocumentoFiscalModel documento;
  final int idDocumentoOrigem;
  final String motivoRetificacao;
  final double valor;

  const NotaRetificativaResponseModel({
    required this.documento,
    required this.idDocumentoOrigem,
    required this.motivoRetificacao,
    required this.valor,
  });

  factory NotaRetificativaResponseModel.fromJson(Map<String, dynamic> json) {
    return NotaRetificativaResponseModel(
      documento: DocumentoFiscalModel.fromJson(
          json['documento'] as Map<String, dynamic>),
      idDocumentoOrigem: json['idDocumentoOrigem'] as int,
      motivoRetificacao: json['motivoRetificacao'] as String? ?? '',
      valor: (json['valor'] as num).toDouble(),
    );
  }
}