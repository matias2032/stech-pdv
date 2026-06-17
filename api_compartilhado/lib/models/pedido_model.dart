// lib/models/pedido_model.dart

int _parseInt(dynamic v) {
  if (v == null) throw ArgumentError('Campo int obrigatório recebeu null');
  if (v is int) return v;
  if (v is double) return v.toInt();
  final s = v.toString().split('.').first;
  final result = int.tryParse(s);
  if (result == null) throw FormatException('Não é um inteiro válido: "$v"');
  return result;
}

int? _parseIntOpt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString().split('.').first);
}

class TipoPagamentoModel {
  final int idTipoPagamento;
  final String tipoPagamento;

  const TipoPagamentoModel({
    required this.idTipoPagamento,
    required this.tipoPagamento,
  });

  factory TipoPagamentoModel.fromJson(Map<String, dynamic> json) =>
      TipoPagamentoModel(
        idTipoPagamento: json['idTipoPagamento'] as int,
        tipoPagamento:   json['tipoPagamento']   as String,
      );

  Map<String, dynamic> toJson() => {
        'idTipoPagamento': idTipoPagamento,
        'tipoPagamento':   tipoPagamento,
      };
}

// ─── Item de Produto (response) ───────────────────────────────────────────────

class ItemPedidoModel {
  final int    idItemPedido;
  final int    idProduto;
  final String nomeProduto;
  final int    quantidade;
  final double precoUnitario;
  final double subtotal;

  const ItemPedidoModel({
    required this.idItemPedido,
    required this.idProduto,
    required this.nomeProduto,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
  });

  factory ItemPedidoModel.fromJson(Map<String, dynamic> json) => ItemPedidoModel(
        idItemPedido:  json['idItemPedido']              as int,
        idProduto:     json['idProduto']                 as int,
        nomeProduto:   json['nomeProduto']               as String,
        quantidade:    json['quantidade']                as int,
        precoUnitario: (json['precoUnitario'] as num?)?.toDouble() ?? 0.0,
        subtotal:      (json['subtotal']      as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'idItemPedido':  idItemPedido,
        'idProduto':     idProduto,
        'nomeProduto':   nomeProduto,
        'quantidade':    quantidade,
        'precoUnitario': precoUnitario,
        'subtotal':      subtotal,
      };
}

// ─── Item de Serviço (response) ───────────────────────────────────────────────

class ItemPedidoServicoModel {
  final int     idItemServico;
  final int     idServico;
  final String? nomeServico;
  final int     quantidade;
  final double  precoUnitario;
  final double  subtotal;
  final String? observacoes;

  const ItemPedidoServicoModel({
    required this.idItemServico,
    required this.idServico,
    this.nomeServico,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
    this.observacoes,
  });

  factory ItemPedidoServicoModel.fromJson(Map<String, dynamic> json) =>
      ItemPedidoServicoModel(
        idItemServico: json['idItemServico']              as int,
        idServico:     json['idServico']                  as int,
        nomeServico:   json['nomeServico']                as String?,
        quantidade:    json['quantidade']                 as int,
        precoUnitario: (json['precoUnitario'] as num?)?.toDouble() ?? 0.0,
        subtotal:      (json['subtotal']      as num?)?.toDouble() ?? 0.0,
        observacoes:   json['observacoes']                as String?,
      );

  Map<String, dynamic> toJson() => {
        'idItemServico': idItemServico,
        'idServico':     idServico,
        'nomeServico':   nomeServico,
        'quantidade':    quantidade,
        'precoUnitario': precoUnitario,
        'subtotal':      subtotal,
        'observacoes':   observacoes,
      };
}

// ─── Pedido (response) ────────────────────────────────────────────────────────

class PedidoModel {
  final int      idPedido;
  final String   referencia;
  final int      idUsuario;
  final int      idTipoPagamento;
  final String   statusPedido;
  final double   total;
  final double   valorPago;
  final double?  troco;
  final String?  pontoReferencia;
  final String?  observacoes;
  final DateTime dataPedido;
  final DateTime? dataFinalizacao;
  final List<ItemPedidoModel>        itensProduto;
  final List<ItemPedidoServicoModel> itensServico;
  final int? idCliente;
  // ── Crédito ─────────────────────────────────────────────
final String tipoVenda; // IMEDIATA | CREDITO
final String? modalidadeCredito; // SEM_PARCELAS | PARCELADO
final String statusPagamento; // PENDENTE | PARCIAL | PAGO
final int? idDocumentoFacturaCredito;
final DateTime? dataAberturaCredito;
final DateTime? dataVencimentoCredito;
final DateTime? dataLiquidacaoCredito;
final String? observacoesCredito;
final double? saldoDevedorCredito;

  const PedidoModel({
    required this.idPedido,
    required this.referencia,
    required this.idUsuario,
    required this.idTipoPagamento,
    required this.statusPedido,
    required this.total,
    required this.valorPago,
    this.troco,
    this.pontoReferencia,
    this.observacoes,
    required this.dataPedido,
    this.dataFinalizacao,
    this.itensProduto = const [],
    this.itensServico = const [],
    this.idCliente,
    this.tipoVenda = 'IMEDIATA',
this.modalidadeCredito,
this.statusPagamento = 'PENDENTE',
this.idDocumentoFacturaCredito,
this.dataAberturaCredito,
this.dataVencimentoCredito,
this.dataLiquidacaoCredito,
this.observacoesCredito,
this.saldoDevedorCredito,
  });

  bool get estaAberto     => statusPedido == 'aberto';
  bool get estaFinalizado => statusPedido == 'finalizado';
  bool get estaCancelado  => statusPedido == 'cancelado';
  bool get ehCredito => tipoVenda == 'CREDITO';
bool get ehVendaImediata => tipoVenda == 'IMEDIATA';

bool get creditoSemParcelas => modalidadeCredito == 'SEM_PARCELAS';
bool get creditoParcelado => modalidadeCredito == 'PARCELADO';

bool get pagamentoPendente => statusPagamento == 'PENDENTE';
bool get pagamentoParcial => statusPagamento == 'PARCIAL';
bool get pagamentoPago => statusPagamento == 'PAGO';

bool get estaEmDivida => statusPedido == 'em dívida';
bool get creditoLiquidado => ehCredito && pagamentoPago;

double get saldoDevedorCalculado {
  if (saldoDevedorCredito != null) return saldoDevedorCredito!;
  return total - valorPago;
}

  // ── HTTP → Model ──────────────────────────────────────────────────

  factory PedidoModel.fromJson(Map<String, dynamic> json) => PedidoModel(
        idPedido:        json['idPedido']        as int,
        referencia:      json['referencia']      as String,
        idUsuario:       json['idUsuario']       as int,
        idTipoPagamento: json['idTipoPagamento'] as int,
        statusPedido:    json['statusPedido']    as String,
        total:           (json['total']          as num).toDouble(),
        valorPago:       (json['valorPago']      as num?)?.toDouble() ?? 0.0,
        troco:           json['troco'] != null
            ? (json['troco'] as num).toDouble()
            : null,
        pontoReferencia: json['pontoReferencia'] as String?,
        observacoes:     json['observacoes']     as String?,
        dataPedido:      DateTime.parse(json['dataPedido'] as String),
        dataFinalizacao: json['dataFinalizacao'] != null
            ? DateTime.tryParse(json['dataFinalizacao'] as String)
            : null,
        itensProduto: (json['itensProduto'] as List<dynamic>?)
                ?.map((e) => ItemPedidoModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        itensServico: (json['itensServico'] as List<dynamic>?)
                ?.map((e) => ItemPedidoServicoModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      idCliente: _parseIntOpt(json['idCliente']),

            tipoVenda: (json['tipoVenda'] as String?) ?? 'IMEDIATA',
modalidadeCredito: json['modalidadeCredito'] as String?,
statusPagamento: (json['statusPagamento'] as String?) ?? 'PENDENTE',
idDocumentoFacturaCredito:
    _parseIntOpt(json['idDocumentoFacturaCredito']),
dataAberturaCredito: json['dataAberturaCredito'] != null
    ? DateTime.tryParse(json['dataAberturaCredito'] as String)
    : null,
dataVencimentoCredito: json['dataVencimentoCredito'] != null
    ? DateTime.tryParse(json['dataVencimentoCredito'] as String)
    : null,
dataLiquidacaoCredito: json['dataLiquidacaoCredito'] != null
    ? DateTime.tryParse(json['dataLiquidacaoCredito'] as String)
    : null,
observacoesCredito: json['observacoesCredito'] as String?,
saldoDevedorCredito: json['saldoDevedorCredito'] != null
    ? (json['saldoDevedorCredito'] as num).toDouble()
    : null,
      );

      

  // ── SQLite → Model ────────────────────────────────────────────────

  factory PedidoModel.fromLocalDb(Map<String, dynamic> row) => PedidoModel(
        idPedido:        row['id']                as int,
        referencia:      (row['referencia']        as String?) ?? '',
        idUsuario:       row['id_usuario']         as int,
        idTipoPagamento: (row['id_tipo_pagamento'] as int?) ?? 0,
        statusPedido:    row['status_pedido']      as String,
        total:           (row['total']             as num).toDouble(),
        valorPago:       (row['valor_pago']        as num?)?.toDouble() ?? 0.0,
        troco:           (row['troco']             as num?)?.toDouble(),
        observacoes:     row['observacoes']        as String?,
        idCliente:       row['id_cliente']         as int?,
        dataPedido:      DateTime.parse(row['data_pedido'] as String),
        dataFinalizacao: row['data_finalizacao'] != null
            ? DateTime.tryParse(row['data_finalizacao'] as String)
            : null,
            tipoVenda: (row['tipo_venda'] as String?) ?? 'IMEDIATA',
modalidadeCredito: row['modalidade_credito'] as String?,
statusPagamento: (row['status_pagamento'] as String?) ?? 'PENDENTE',
idDocumentoFacturaCredito: row['id_documento_factura_credito'] as int?,
dataAberturaCredito: row['data_abertura_credito'] != null
    ? DateTime.tryParse(row['data_abertura_credito'] as String)
    : null,
dataVencimentoCredito: row['data_vencimento_credito'] != null
    ? DateTime.tryParse(row['data_vencimento_credito'] as String)
    : null,
dataLiquidacaoCredito: row['data_liquidacao_credito'] != null
    ? DateTime.tryParse(row['data_liquidacao_credito'] as String)
    : null,
observacoesCredito: row['observacoes_credito'] as String?,
saldoDevedorCredito: (row['saldo_devedor_credito'] as num?)?.toDouble(),
        itensProduto: const [], // carregados separadamente via PedidoDao
        itensServico: const [],
      );

  // ── Model → JSON (HTTP) ───────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'idPedido':        idPedido,
        'referencia':      referencia,
        'idUsuario':       idUsuario,
        'idTipoPagamento': idTipoPagamento,
        'statusPedido':    statusPedido,
        'total':           total,
        'valorPago':       valorPago,
        'troco':           troco,
        'pontoReferencia': pontoReferencia,
        'observacoes':     observacoes,
        'dataPedido':      dataPedido.toIso8601String(),
        'dataFinalizacao': dataFinalizacao?.toIso8601String(),
        'itensProduto':    itensProduto.map((e) => e.toJson()).toList(),
        'itensServico':    itensServico.map((e) => e.toJson()).toList(),
        'idCliente':       idCliente,
        'tipoVenda': tipoVenda,
'modalidadeCredito': modalidadeCredito,
'statusPagamento': statusPagamento,
'idDocumentoFacturaCredito': idDocumentoFacturaCredito,
'dataAberturaCredito': dataAberturaCredito?.toIso8601String(),
'dataVencimentoCredito': dataVencimentoCredito?.toIso8601String().split('T').first,
'dataLiquidacaoCredito': dataLiquidacaoCredito?.toIso8601String(),
'observacoesCredito': observacoesCredito,
'saldoDevedorCredito': saldoDevedorCredito,
      };

  // ── Model → SQLite ────────────────────────────────────────────────

  Map<String, dynamic> toLocalDb() => {
        'id':                idPedido,
        'local_id':          null,
        'referencia':        referencia,
        'status_pedido':     statusPedido,
        'total':             total,
        'valor_pago':        valorPago,
        'troco':             troco,
        'observacoes':       observacoes,
        'id_cliente':        idCliente,
        'id_tipo_pagamento': idTipoPagamento,
        'id_usuario':        idUsuario,
        'data_pedido':       dataPedido.toIso8601String(),
        'data_finalizacao':  dataFinalizacao?.toIso8601String(),
        'tipo_venda': tipoVenda,
'modalidade_credito': modalidadeCredito,
'status_pagamento': statusPagamento,
'id_documento_factura_credito': idDocumentoFacturaCredito,
'data_abertura_credito': dataAberturaCredito?.toIso8601String(),
'data_vencimento_credito': dataVencimentoCredito?.toIso8601String().split('T').first,
'data_liquidacao_credito': dataLiquidacaoCredito?.toIso8601String(),
'observacoes_credito': observacoesCredito,
'saldo_devedor_credito': saldoDevedorCredito,
        'sync_status':       'synced',
        'updated_at':        DateTime.now().toIso8601String(),
      };

  // ── copyWith ──────────────────────────────────────────────────────

  PedidoModel copyWith({
    int?    idPedido,
    String? referencia,
    int?    idUsuario,
    int?    idTipoPagamento,
    String? statusPedido,
    double? total,
    double? valorPago,
    double? troco,
    String? pontoReferencia,
    String? observacoes,
    DateTime? dataPedido,
    DateTime? dataFinalizacao,
    List<ItemPedidoModel>?        itensProduto,
    List<ItemPedidoServicoModel>? itensServico,
    int?    idCliente,
    String? tipoVenda,
String? modalidadeCredito,
String? statusPagamento,
int? idDocumentoFacturaCredito,
DateTime? dataAberturaCredito,
DateTime? dataVencimentoCredito,
DateTime? dataLiquidacaoCredito,
String? observacoesCredito,
double? saldoDevedorCredito,
  }) => PedidoModel(
        idPedido:        idPedido        ?? this.idPedido,
        referencia:      referencia      ?? this.referencia,
        idUsuario:       idUsuario       ?? this.idUsuario,
        idTipoPagamento: idTipoPagamento ?? this.idTipoPagamento,
        statusPedido:    statusPedido    ?? this.statusPedido,
        total:           total           ?? this.total,
        valorPago:       valorPago       ?? this.valorPago,
        troco:           troco           ?? this.troco,
        pontoReferencia: pontoReferencia ?? this.pontoReferencia,
        observacoes:     observacoes     ?? this.observacoes,
        dataPedido:      dataPedido      ?? this.dataPedido,
        dataFinalizacao: dataFinalizacao ?? this.dataFinalizacao,
        itensProduto:    itensProduto    ?? this.itensProduto,
        itensServico:    itensServico    ?? this.itensServico,
        idCliente:       idCliente       ?? this.idCliente,
        tipoVenda: tipoVenda ?? this.tipoVenda,
modalidadeCredito: modalidadeCredito ?? this.modalidadeCredito,
statusPagamento: statusPagamento ?? this.statusPagamento,
idDocumentoFacturaCredito:
    idDocumentoFacturaCredito ?? this.idDocumentoFacturaCredito,
dataAberturaCredito: dataAberturaCredito ?? this.dataAberturaCredito,
dataVencimentoCredito: dataVencimentoCredito ?? this.dataVencimentoCredito,
dataLiquidacaoCredito: dataLiquidacaoCredito ?? this.dataLiquidacaoCredito,
observacoesCredito: observacoesCredito ?? this.observacoesCredito,
saldoDevedorCredito: saldoDevedorCredito ?? this.saldoDevedorCredito,
      );

  @override
  bool operator ==(Object other) => other is PedidoModel && other.idPedido == idPedido;

  @override
  int get hashCode => idPedido.hashCode;

  @override
  String toString() =>
      'PedidoModel{idPedido: $idPedido, referencia: $referencia, status: $statusPedido}';
}

class ParcelaCreditoModel {
  final int idParcela;
  final int idPedido;
  final int numeroParcela;
  final double valorParcela;
  final double valorPago;
  final double? saldoParcela;
  final DateTime dataVencimento;
  final DateTime? dataPagamento;
  final String statusParcela;
  final String? observacoes;

  const ParcelaCreditoModel({
    required this.idParcela,
    required this.idPedido,
    required this.numeroParcela,
    required this.valorParcela,
    required this.valorPago,
    this.saldoParcela,
    required this.dataVencimento,
    this.dataPagamento,
    required this.statusParcela,
    this.observacoes,
  });

  bool get pendente => statusParcela == 'PENDENTE';
  bool get parcial => statusParcela == 'PARCIAL';
  bool get paga => statusParcela == 'PAGA';
  bool get vencida => statusParcela == 'VENCIDA';
  bool get cancelada => statusParcela == 'CANCELADA';

  double get saldoCalculado {
    if (saldoParcela != null) return saldoParcela!;
    return valorParcela - valorPago;
  }

  factory ParcelaCreditoModel.fromJson(Map<String, dynamic> json) =>
      ParcelaCreditoModel(
        idParcela: int.parse(json['idParcela'].toString()),
        idPedido: int.parse(json['idPedido'].toString()),
        numeroParcela: int.parse(json['numeroParcela'].toString()),
        valorParcela: (json['valorParcela'] as num).toDouble(),
        valorPago: (json['valorPago'] as num?)?.toDouble() ?? 0.0,
        saldoParcela: json['saldoParcela'] != null
            ? (json['saldoParcela'] as num).toDouble()
            : null,
        dataVencimento: DateTime.parse(json['dataVencimento'] as String),
        dataPagamento: json['dataPagamento'] != null
            ? DateTime.tryParse(json['dataPagamento'] as String)
            : null,
        statusParcela: (json['statusParcela'] as String?) ?? 'PENDENTE',
        observacoes: json['observacoes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'idParcela': idParcela,
        'idPedido': idPedido,
        'numeroParcela': numeroParcela,
        'valorParcela': valorParcela,
        'valorPago': valorPago,
        'saldoParcela': saldoParcela,
        'dataVencimento': dataVencimento.toIso8601String().split('T').first,
        'dataPagamento': dataPagamento?.toIso8601String(),
        'statusParcela': statusParcela,
        'observacoes': observacoes,
      };
}

class PagamentoCreditoModel {
  final int idPagamentoCredito;
  final String referencia;
  final int idPedido;
  final int? idParcela;
  final int idTipoPagamento;
  final int idUsuario;
final int? idDocumentoRecibo;
  final double valorPago;
  final DateTime dataPagamento;
  final String? observacoes;

  const PagamentoCreditoModel({
    required this.idPagamentoCredito,
    required this.referencia,
    required this.idPedido,
    this.idParcela,
    required this.idTipoPagamento,
    required this.idUsuario,
    this.idDocumentoRecibo,
    required this.valorPago,
    required this.dataPagamento,
    this.observacoes,
  });

factory PagamentoCreditoModel.fromJson(Map<String, dynamic> json) =>
    PagamentoCreditoModel(

idPagamentoCredito: _parseIntOpt(json['idPagamentoCredito']) ?? 0,
      referencia:         (json['referencia'] as String?) ?? '',
      idPedido:           _parseIntOpt(json['idPedido']) ?? 0,
      idParcela:          _parseIntOpt(json['idParcela']),
      idTipoPagamento:    _parseIntOpt(json['idTipoPagamento']) ?? 0,
      idUsuario:          _parseIntOpt(json['idUsuario']) ?? 0,
      idDocumentoRecibo:  _parseIntOpt(json['idDocumentoRecibo']),
      valorPago:          (json['valorPago'] as num).toDouble(),
      dataPagamento:      DateTime.parse(json['dataPagamento'] as String),
      observacoes:        json['observacoes'] as String?,
    );

  Map<String, dynamic> toJson() => {
        'idPagamentoCredito': idPagamentoCredito,
        'referencia':         referencia,
        'idPedido':           idPedido,
        'idParcela':          idParcela,
        'idTipoPagamento':    idTipoPagamento,
        'idUsuario':          idUsuario,
        'idDocumentoRecibo':  idDocumentoRecibo,
        'valorPago':          valorPago,
        'dataPagamento':      dataPagamento.toIso8601String(),
        'observacoes':        observacoes,
      };

}

// ═══════════════════════════════════════════════════════════════════════════
// REQUEST DTOs
// ═══════════════════════════════════════════════════════════════════════════

class ItemPedidoRequestModel {
  final int idProduto;
  final int quantidade;

  const ItemPedidoRequestModel({
    required this.idProduto,
    required this.quantidade,
  });

  Map<String, dynamic> toJson() => {
        'idProduto':  idProduto,
        'quantidade': quantidade,
      };
}

class ItemServicoRequestModel {
  final int     idServico;
  final int     quantidade;
  final String? observacoes;

  const ItemServicoRequestModel({
    required this.idServico,
    required this.quantidade,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        'idServico':   idServico,
        'quantidade':  quantidade,
        'observacoes': observacoes,
      };
}

class PedidoRequestModel {
  final int     idUsuario;
  final int     idTipoPagamento;
  final String? pontoReferencia;
  final String? observacoes;
  final List<ItemPedidoRequestModel>  itensProduto;
  final List<ItemServicoRequestModel> itensServico;

  const PedidoRequestModel({
    required this.idUsuario,
    required this.idTipoPagamento,
    this.pontoReferencia,
    this.observacoes,
    this.itensProduto = const [],
    this.itensServico = const [],
  });

  Map<String, dynamic> toJson() => {
        'idUsuario':       idUsuario,
        'idTipoPagamento': idTipoPagamento,
        'pontoReferencia': pontoReferencia,
        'observacoes':     observacoes,
        'itensProduto':    itensProduto.map((e) => e.toJson()).toList(),
        'itensServico':    itensServico.map((e) => e.toJson()).toList(),
      };
}

class EditarItemRequestModel {
  final int novaQuantidade;
  const EditarItemRequestModel({required this.novaQuantidade});
  Map<String, dynamic> toJson() => {'novaQuantidade': novaQuantidade};
}

class FinalizarPedidoRequestModel {
  final int     idTipoPagamento;
  final double  valorPago;
  final String? observacoes;
  final int?    idCliente;
  final String? nomeClienteSingular;
  final String? apelidoClienteSingular;

  const FinalizarPedidoRequestModel({
    required this.idTipoPagamento,
    required this.valorPago,
    this.observacoes,
    this.idCliente,
    this.nomeClienteSingular,
    this.apelidoClienteSingular,
  });

  Map<String, dynamic> toJson() => {
        'idTipoPagamento':        idTipoPagamento,
        'valorPago':              valorPago,
        'observacoes':            observacoes,
        'idCliente':              idCliente,
        'nomeClienteSingular':    nomeClienteSingular,
        'apelidoClienteSingular': apelidoClienteSingular,
      };
}

class CancelamentoPedidoRequestModel {
  final int     idUsuarioCancelou;
  final String? motivo;

  const CancelamentoPedidoRequestModel({
    required this.idUsuarioCancelou,
    this.motivo,
  });

  Map<String, dynamic> toJson() => {
        'idUsuarioCancelou': idUsuarioCancelou,
        'motivo':            motivo,
      };
}

class DeclararCreditoRequestModel {
  final String modalidadeCredito;
  final int idUsuario;
  final int? idCliente;           // ← NOVO
  final String? codigoAt;
  final DateTime? dataVencimento;
  final String? observacoesCredito;

  const DeclararCreditoRequestModel({
    required this.modalidadeCredito,
    required this.idUsuario,
    this.idCliente,               // ← NOVO
    this.codigoAt,
    this.dataVencimento,
    this.observacoesCredito,
  });

  Map<String, dynamic> toJson() => {
        'modalidadeCredito': modalidadeCredito,
        'idUsuario': idUsuario,
        if (idCliente != null) 'idCliente': idCliente,  // ← NOVO
        if (codigoAt != null) 'codigoAt': codigoAt,
        if (dataVencimento != null)
          'dataVencimento': dataVencimento!.toIso8601String().split('T').first,
        if (observacoesCredito != null)
          'observacoesCredito': observacoesCredito,
      };
}

class CriarParcelaItemRequestModel {
  final int numeroParcela;
  final double valorParcela;
  final DateTime dataVencimento;

  const CriarParcelaItemRequestModel({
    required this.numeroParcela,
    required this.valorParcela,
    required this.dataVencimento,
  });

  Map<String, dynamic> toJson() => {
        'numeroParcela': numeroParcela,
        'valorParcela': valorParcela,
        'dataVencimento': dataVencimento.toIso8601String().split('T').first,
      };
}

class CriarParcelasRequestModel {
  final List<CriarParcelaItemRequestModel> parcelas;

  const CriarParcelasRequestModel({
    required this.parcelas,
  });

  Map<String, dynamic> toJson() => {
        'parcelas': parcelas.map((e) => e.toJson()).toList(),
      };
}

class RegistarPagamentoCreditoRequestModel {
  final int? idParcela;
  final int idTipoPagamento;
  final int idUsuario;
  final double valorPago;
  final String? codigoAt;
  final String? observacoes;

  const RegistarPagamentoCreditoRequestModel({
    this.idParcela,
    required this.idTipoPagamento,
    required this.idUsuario,
    required this.valorPago,
    this.codigoAt,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        if (idParcela != null) 'idParcela': idParcela,
        'idTipoPagamento': idTipoPagamento,
        'idUsuario': idUsuario,
        'valorPago': valorPago,
        if (codigoAt != null) 'codigoAt': codigoAt,
        if (observacoes != null) 'observacoes': observacoes,
      };
}

