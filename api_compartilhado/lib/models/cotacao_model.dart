// lib/models/cotacao_model.dart

// ═══════════════════════════════════════════════════════════════════════════
// RESPONSE MODELS
// Espelho de CotacaoResponseDTO.Detalhe / Cotacao.java
// ═══════════════════════════════════════════════════════════════════════════

// ─── Item de Produto da Cotação (response) ────────────────────────────────

class CotacaoItemProdutoModel {
  final int idItemCotacaoProduto;
  final int idProduto;
  final String? nomeProduto;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;
  final String? observacoes;

  const CotacaoItemProdutoModel({
    required this.idItemCotacaoProduto,
    required this.idProduto,
    this.nomeProduto,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
    this.observacoes,
  });

  // ── HTTP → Model ──────────────────────────────────────────────────

  factory CotacaoItemProdutoModel.fromJson(Map<String, dynamic> json) =>
      CotacaoItemProdutoModel(
        idItemCotacaoProduto: json['idItemCotacaoProduto'] as int,
        idProduto:            json['idProduto']            as int,
        nomeProduto:          json['nomeProduto']          as String?,
        quantidade:           json['quantidade']           as int,
        precoUnitario: (json['precoUnitario'] as num?)?.toDouble() ?? 0.0,
        subtotal:      (json['subtotal']      as num?)?.toDouble() ?? 0.0,
        observacoes:          json['observacoes']          as String?,
      );

  // ── Model → JSON (HTTP) ───────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'idItemCotacaoProduto': idItemCotacaoProduto,
        'idProduto':            idProduto,
        'nomeProduto':          nomeProduto,
        'quantidade':           quantidade,
        'precoUnitario':        precoUnitario,
        'subtotal':             subtotal,
        'observacoes':          observacoes,
      };

  // ── SQLite → Model ────────────────────────────────────────────────

  factory CotacaoItemProdutoModel.fromLocalDb(Map<String, dynamic> row) =>
      CotacaoItemProdutoModel(
        idItemCotacaoProduto: row['id']             as int,
        idProduto:            row['id_produto']     as int,
        nomeProduto:          row['nome_produto']   as String?,
        quantidade:           row['quantidade']     as int,
        precoUnitario: (row['preco_unitario'] as num?)?.toDouble() ?? 0.0,
        subtotal:      (row['subtotal']       as num?)?.toDouble() ?? 0.0,
        observacoes:          row['observacoes']    as String?,
      );

  // ── Model → SQLite ────────────────────────────────────────────────

  Map<String, dynamic> toLocalDb(int idCotacao) => {
        'id':             idItemCotacaoProduto,
        'id_cotacao':     idCotacao,
        'id_produto':     idProduto,
        'nome_produto':   nomeProduto,
        'quantidade':     quantidade,
        'preco_unitario': precoUnitario,
        'subtotal':       subtotal,
        'observacoes':    observacoes,
      };
}

// ─── Item de Serviço da Cotação (response) ─────────────────────────────────

class CotacaoItemServicoModel {
  final int idItemCotacaoServico;
  final int idServico;
  final String? nomeServico;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;
  final String? observacoes;

  const CotacaoItemServicoModel({
    required this.idItemCotacaoServico,
    required this.idServico,
    this.nomeServico,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
    this.observacoes,
  });

  // ── HTTP → Model ──────────────────────────────────────────────────

  factory CotacaoItemServicoModel.fromJson(Map<String, dynamic> json) =>
      CotacaoItemServicoModel(
        idItemCotacaoServico: json['idItemCotacaoServico'] as int,
        idServico:            json['idServico']            as int,
        nomeServico:          json['nomeServico']          as String?,
        quantidade:           json['quantidade']           as int,
        precoUnitario: (json['precoUnitario'] as num?)?.toDouble() ?? 0.0,
        subtotal:      (json['subtotal']      as num?)?.toDouble() ?? 0.0,
        observacoes:          json['observacoes']          as String?,
      );

  // ── Model → JSON (HTTP) ───────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'idItemCotacaoServico': idItemCotacaoServico,
        'idServico':            idServico,
        'nomeServico':          nomeServico,
        'quantidade':           quantidade,
        'precoUnitario':        precoUnitario,
        'subtotal':             subtotal,
        'observacoes':          observacoes,
      };

  // ── SQLite → Model ────────────────────────────────────────────────

  factory CotacaoItemServicoModel.fromLocalDb(Map<String, dynamic> row) =>
      CotacaoItemServicoModel(
        idItemCotacaoServico: row['id']           as int,
        idServico:            row['id_servico']   as int,
        nomeServico:          row['nome_servico'] as String?,
        quantidade:           row['quantidade']   as int,
        precoUnitario: (row['preco_unitario'] as num?)?.toDouble() ?? 0.0,
        subtotal:      (row['subtotal']       as num?)?.toDouble() ?? 0.0,
        observacoes:          row['observacoes']  as String?,
      );

  // ── Model → SQLite ────────────────────────────────────────────────

  Map<String, dynamic> toLocalDb(int idCotacao) => {
        'id':             idItemCotacaoServico,
        'id_cotacao':     idCotacao,
        'id_servico':     idServico,
        'nome_servico':   nomeServico,
        'quantidade':     quantidade,
        'preco_unitario': precoUnitario,
        'subtotal':       subtotal,
        'observacoes':    observacoes,
      };
}

// ─── Cotação (response) ─────────────────────────────────────────────────────

class CotacaoModel {
  final int idCotacao;
  final String referencia;
  final int? idCliente;
  final String? nomeCliente;
  final int idUsuario;
  final String? nomeUsuario;
  final String statusCotacao;
  final double total;
  final DateTime? validadeAte;
  final String? observacoes;
  final int? idPedidoConvertido;
  final String? referenciaPedidoConvertido;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CotacaoItemProdutoModel> itensProduto;
  final List<CotacaoItemServicoModel> itensServico;

  const CotacaoModel({
    required this.idCotacao,
    required this.referencia,
    this.idCliente,
    this.nomeCliente,
    required this.idUsuario,
    this.nomeUsuario,
    required this.statusCotacao,
    required this.total,
    this.validadeAte,
    this.observacoes,
    this.idPedidoConvertido,
    this.referenciaPedidoConvertido,
    this.createdAt,
    this.updatedAt,
    this.itensProduto = const [],
    this.itensServico = const [],
  });

  // ── Helpers de negócio (espelho de Cotacao.java) ───────────────────

  static const _statusNaoEditaveis = ['CONVERTIDA', 'CANCELADA', 'EXPIRADA'];

  bool get isEditavel => !_statusNaoEditaveis.contains(statusCotacao);

  bool get temItens => itensProduto.isNotEmpty || itensServico.isNotEmpty;

  bool get estaAberta    => statusCotacao == 'ABERTA';
  bool get estaEnviada   => statusCotacao == 'ENVIADA';
  bool get estaAprovada  => statusCotacao == 'APROVADA';
  bool get estaConvertida => statusCotacao == 'CONVERTIDA';
  bool get estaCancelada  => statusCotacao == 'CANCELADA';
  bool get estaExpirada   => statusCotacao == 'EXPIRADA';

  // ── HTTP → Model ──────────────────────────────────────────────────

  factory CotacaoModel.fromJson(Map<String, dynamic> json) => CotacaoModel(
        idCotacao:   json['idCotacao']   as int,
        referencia:  json['referencia']  as String,
        idCliente:   json['idCliente'] != null
            ? int.tryParse(json['idCliente'].toString())
            : null,
        nomeCliente: json['nomeCliente'] as String?,
        idUsuario:   json['idUsuario']   as int,
        nomeUsuario: json['nomeUsuario'] as String?,
        statusCotacao: json['statusCotacao'] as String,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        validadeAte: json['validadeAte'] != null
            ? DateTime.tryParse(json['validadeAte'] as String)
            : null,
        observacoes: json['observacoes'] as String?,
        idPedidoConvertido: json['idPedidoConvertido'] != null
            ? int.tryParse(json['idPedidoConvertido'].toString())
            : null,
        referenciaPedidoConvertido:
            json['referenciaPedidoConvertido'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
        itensProduto: (json['itensProduto'] as List<dynamic>?)
                ?.map((e) =>
                    CotacaoItemProdutoModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        itensServico: (json['itensServico'] as List<dynamic>?)
                ?.map((e) =>
                    CotacaoItemServicoModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  // ── SQLite → Model ────────────────────────────────────────────────
  // (itensProduto / itensServico carregados separadamente via CotacaoDao)

  factory CotacaoModel.fromLocalDb(Map<String, dynamic> row) => CotacaoModel(
        idCotacao:   row['id']           as int,
        referencia:  (row['referencia']  as String?) ?? '',
        idCliente:   row['id_cliente']   as int?,
        nomeCliente: row['nome_cliente'] as String?,
        idUsuario:   row['id_usuario']   as int,
        nomeUsuario: row['nome_usuario'] as String?,
        statusCotacao: row['status_cotacao'] as String,
        total: (row['total'] as num?)?.toDouble() ?? 0.0,
        validadeAte: row['validade_ate'] != null
            ? DateTime.tryParse(row['validade_ate'] as String)
            : null,
        observacoes: row['observacoes'] as String?,
        idPedidoConvertido: row['id_pedido_convertido'] as int?,
        referenciaPedidoConvertido:
            row['referencia_pedido_convertido'] as String?,
        createdAt: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'] as String)
            : null,
        updatedAt: row['updated_at'] != null
            ? DateTime.tryParse(row['updated_at'] as String)
            : null,
        itensProduto: const [],
        itensServico: const [],
      );

  // ── Model → JSON (HTTP) ───────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'idCotacao':   idCotacao,
        'referencia':  referencia,
        'idCliente':   idCliente,
        'nomeCliente': nomeCliente,
        'idUsuario':   idUsuario,
        'nomeUsuario': nomeUsuario,
        'statusCotacao': statusCotacao,
        'total':       total,
        'validadeAte': validadeAte?.toIso8601String().split('T').first,
        'observacoes': observacoes,
        'idPedidoConvertido': idPedidoConvertido,
        'referenciaPedidoConvertido': referenciaPedidoConvertido,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'itensProduto': itensProduto.map((e) => e.toJson()).toList(),
        'itensServico': itensServico.map((e) => e.toJson()).toList(),
      };

  // ── Model → SQLite ────────────────────────────────────────────────

  Map<String, dynamic> toLocalDb({String syncStatus = 'synced'}) => {
        'id':           idCotacao,
        'local_id':     null,
        'referencia':   referencia,
        'id_cliente':   idCliente,
        'nome_cliente': nomeCliente,
        'id_usuario':   idUsuario,
        'nome_usuario': nomeUsuario,
        'status_cotacao': statusCotacao,
        'total':        total,
        'validade_ate': validadeAte?.toIso8601String().split('T').first,
        'observacoes':  observacoes,
        'id_pedido_convertido': idPedidoConvertido,
        'referencia_pedido_convertido': referenciaPedidoConvertido,
        'created_at': createdAt?.toIso8601String(),
        'sync_status': syncStatus,
        'updated_at':  DateTime.now().toIso8601String(),
      };

  // ── copyWith ──────────────────────────────────────────────────────

  CotacaoModel copyWith({
    int? idCotacao,
    String? referencia,
    int? idCliente,
    bool removerCliente = false,
    String? nomeCliente,
    int? idUsuario,
    String? nomeUsuario,
    String? statusCotacao,
    double? total,
    DateTime? validadeAte,
    String? observacoes,
    int? idPedidoConvertido,
    String? referenciaPedidoConvertido,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CotacaoItemProdutoModel>? itensProduto,
    List<CotacaoItemServicoModel>? itensServico,
  }) => CotacaoModel(
        idCotacao:   idCotacao   ?? this.idCotacao,
        referencia:  referencia  ?? this.referencia,
        idCliente:   removerCliente ? null : (idCliente ?? this.idCliente),
        nomeCliente: removerCliente ? null : (nomeCliente ?? this.nomeCliente),
        idUsuario:   idUsuario   ?? this.idUsuario,
        nomeUsuario: nomeUsuario ?? this.nomeUsuario,
        statusCotacao: statusCotacao ?? this.statusCotacao,
        total:       total       ?? this.total,
        validadeAte: validadeAte ?? this.validadeAte,
        observacoes: observacoes ?? this.observacoes,
        idPedidoConvertido: idPedidoConvertido ?? this.idPedidoConvertido,
        referenciaPedidoConvertido:
            referenciaPedidoConvertido ?? this.referenciaPedidoConvertido,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        itensProduto: itensProduto ?? this.itensProduto,
        itensServico: itensServico ?? this.itensServico,
      );

  @override
  bool operator ==(Object other) =>
      other is CotacaoModel && other.idCotacao == idCotacao;

  @override
  int get hashCode => idCotacao.hashCode;

  @override
  String toString() =>
      'CotacaoModel{idCotacao: $idCotacao, referencia: $referencia, status: $statusCotacao}';
}

// ═══════════════════════════════════════════════════════════════════════════
// REQUEST DTOs
// Espelho de CotacaoRequestDTO.java
// ═══════════════════════════════════════════════════════════════════════════

// ─── a) Criar Cotação ───────────────────────────────────────────────────────

class CriarCotacaoRequestModel {
  final int idUsuario;
  final int? idCliente;
  final DateTime? validadeAte;
  final String? observacoes;

  const CriarCotacaoRequestModel({
    required this.idUsuario,
    this.idCliente,
    this.validadeAte,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        'idUsuario':   idUsuario,
        'idCliente':   idCliente,
        'validadeAte': validadeAte?.toIso8601String().split('T').first,
        'observacoes': observacoes,
      };
}

// ─── b) Actualizar Cotação ──────────────────────────────────────────────────
//
// Atenção (espelha CotacaoService.atualizarCotacao):
//  • idCliente == null  → REMOVE o cliente associado.
//  • validadeAte == null / observacoes == null / statusCotacao == null
//    → mantém o valor actual (não altera).

class AtualizarCotacaoRequestModel {
  final int? idCliente;
  final DateTime? validadeAte;
  final String? observacoes;
  final String? statusCotacao;

  const AtualizarCotacaoRequestModel({
    this.idCliente,
    this.validadeAte,
    this.observacoes,
    this.statusCotacao,
  });

  Map<String, dynamic> toJson() => {
        'idCliente':     idCliente,
        'validadeAte':   validadeAte?.toIso8601String().split('T').first,
        'observacoes':   observacoes,
        'statusCotacao': statusCotacao,
      };
}

// ─── c) Adicionar Item de Produto ───────────────────────────────────────────

class AdicionarProdutoCotacaoRequestModel {
  final int idProduto;
  final int quantidade;
  final double? precoUnitario;
  final String? observacoes;

  const AdicionarProdutoCotacaoRequestModel({
    required this.idProduto,
    required this.quantidade,
    this.precoUnitario,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        'idProduto':     idProduto,
        'quantidade':    quantidade,
        'precoUnitario': precoUnitario,
        'observacoes':   observacoes,
      };
}

// ─── d) Adicionar Item de Serviço ───────────────────────────────────────────

class AdicionarServicoCotacaoRequestModel {
  final int idServico;
  final int quantidade;
  final double? precoUnitario;
  final String? observacoes;

  const AdicionarServicoCotacaoRequestModel({
    required this.idServico,
    required this.quantidade,
    this.precoUnitario,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        'idServico':     idServico,
        'quantidade':    quantidade,
        'precoUnitario': precoUnitario,
        'observacoes':   observacoes,
      };
}

// ─── e) Actualizar Item (produto ou serviço) ────────────────────────────────

class AtualizarItemCotacaoRequestModel {
  final int quantidade;
  final double? precoUnitario;
  final String? observacoes;

  const AtualizarItemCotacaoRequestModel({
    required this.quantidade,
    this.precoUnitario,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        'quantidade':    quantidade,
        'precoUnitario': precoUnitario,
        'observacoes':   observacoes,
      };
}

// ─── f) Converter Cotação em Pedido ─────────────────────────────────────────

class ConverterCotacaoEmPedidoRequestModel {
  final int idTipoPagamento;
  final String? observacoes;

  const ConverterCotacaoEmPedidoRequestModel({
    required this.idTipoPagamento,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        'idTipoPagamento': idTipoPagamento,
        'observacoes':     observacoes,
      };
}