/// Espelha PedidoResponseDTO, ItemPedidoResponseDTO, ItemServicoResponseDTO,
/// TipoPagamentoResponseDTO e todos os Request DTOs do Java.

// ─── Tipos de Pagamento ───────────────────────────────────────────────────────

class TipoPagamentoModel {
  final int idTipoPagamento;
  final String tipoPagamento;

  const TipoPagamentoModel({
    required this.idTipoPagamento,
    required this.tipoPagamento,
  });

  factory TipoPagamentoModel.fromJson(Map<String, dynamic> json) {
    return TipoPagamentoModel(
      idTipoPagamento: json['idTipoPagamento'] as int,
      tipoPagamento: json['tipoPagamento'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'idTipoPagamento': idTipoPagamento,
        'tipoPagamento': tipoPagamento,
      };
}

// ─── Item de Produto (response) ──────────────────────────────────────────────

/// Espelha ItemPedidoResponseDTO.
class ItemPedidoModel {
  final int idItemPedido;
  final int idProduto;
  final String nomeProduto;
  final int quantidade;
  final double precoUnitario;
  final double subtotal; // gerado pela BD (quantidade * precoUnitario)

  const ItemPedidoModel({
    required this.idItemPedido,
    required this.idProduto,
    required this.nomeProduto,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
  });

// ItemPedidoModel.fromJson — substituir:
factory ItemPedidoModel.fromJson(Map<String, dynamic> json) {
  return ItemPedidoModel(
    idItemPedido:  json['idItemPedido']  as int,
    idProduto:     json['idProduto']     as int,
    nomeProduto:   json['nomeProduto']   as String,
    quantidade:    json['quantidade']    as int,
    precoUnitario: (json['precoUnitario'] as num?)?.toDouble() ?? 0.0,
    subtotal:      (json['subtotal']      as num?)?.toDouble() ?? 0.0,  // ✅
  );
}



  Map<String, dynamic> toJson() => {
        'idItemPedido': idItemPedido,
        'idProduto': idProduto,
        'nomeProduto': nomeProduto,
        'quantidade': quantidade,
        'precoUnitario': precoUnitario,
        'subtotal': subtotal,
      };
}

// ─── Item de Serviço (response) ───────────────────────────────────────────────

/// Espelha ItemServicoResponseDTO.
class ItemPedidoServicoModel {
  final int idItemServico;
  final int idServico;
  final String? nomeServico;
  final int quantidade;
  final double precoUnitario;
  final double subtotal; // gerado pela BD
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

// ItemPedidoServicoModel.fromJson — substituir:
factory ItemPedidoServicoModel.fromJson(Map<String, dynamic> json) {
  return ItemPedidoServicoModel(
    idItemServico:  json['idItemServico']  as int,
    idServico:      json['idServico']      as int,
    nomeServico:    json['nomeServico']    as String?,
    quantidade:     json['quantidade']     as int,
    precoUnitario:  (json['precoUnitario'] as num?)?.toDouble() ?? 0.0,
    subtotal:       (json['subtotal']      as num?)?.toDouble() ?? 0.0,  // ✅
    observacoes:    json['observacoes']    as String?,
  );
}

  Map<String, dynamic> toJson() => {
        'idItemServico': idItemServico,
        'idServico': idServico,
        'nomeServico': nomeServico,
        'quantidade': quantidade,
        'precoUnitario': precoUnitario,
        'subtotal': subtotal,
        'observacoes': observacoes,
      };
}

// ─── Pedido (response) ────────────────────────────────────────────────────────

/// Espelha PedidoResponseDTO.
class PedidoModel {
  final int idPedido;
  final String referencia; // ex: PED-20260521-0001
  final int idUsuario;
  final int idTipoPagamento;
  final String statusPedido; // 'aberto' | 'finalizado' | 'cancelado'
  final double total;
  final double valorPago;
  final double? troco; // calculado pela BD (GREATEST(valorPago - total, 0))
  final String? pontoReferencia;
  final String? observacoes;
  final DateTime dataPedido;
  final DateTime? dataFinalizacao;
  final List<ItemPedidoModel> itensProduto;
  final List<ItemPedidoServicoModel> itensServico;
  final int? idCliente;
  

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
  });

  bool get estaAberto => statusPedido == 'aberto';
  bool get estaFinalizado => statusPedido == 'finalizado';
  bool get estaCancelado => statusPedido == 'cancelado';

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      idPedido: json['idPedido'] as int,
      referencia: json['referencia'] as String,
      idUsuario: json['idUsuario'] as int,
      idTipoPagamento: json['idTipoPagamento'] as int,
      statusPedido: json['statusPedido'] as String,
      total: (json['total'] as num).toDouble(),
      valorPago: (json['valorPago'] as num?)?.toDouble() ?? 0.0,
      troco: json['troco'] != null ? (json['troco'] as num).toDouble() : null,
      pontoReferencia: json['pontoReferencia'] as String?,
      observacoes: json['observacoes'] as String?,
      dataPedido: DateTime.parse(json['dataPedido'] as String),
      dataFinalizacao: json['dataFinalizacao'] != null
          ? DateTime.tryParse(json['dataFinalizacao'] as String)
          : null,
      itensProduto: (json['itensProduto'] as List<dynamic>?)
              ?.map((e) => ItemPedidoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      itensServico: (json['itensServico'] as List<dynamic>?)
              ?.map((e) =>
                  ItemPedidoServicoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
              idCliente: json['idCliente'] != null
        ? int.tryParse(json['idCliente'].toString())
        : null,  // ← conversão segura de String ou int
);
  }

  Map<String, dynamic> toJson() => {
        'idPedido': idPedido,
        'referencia': referencia,
        'idUsuario': idUsuario,
        'idTipoPagamento': idTipoPagamento,
        'statusPedido': statusPedido,
        'total': total,
        'valorPago': valorPago,
        'troco': troco,
        'pontoReferencia': pontoReferencia,
        'observacoes': observacoes,
        'dataPedido': dataPedido.toIso8601String(),
        'dataFinalizacao': dataFinalizacao?.toIso8601String(),
        'itensProduto': itensProduto.map((e) => e.toJson()).toList(),
        'itensServico': itensServico.map((e) => e.toJson()).toList(),
        'idCliente': idCliente,
      };

  PedidoModel copyWith({
    int? idPedido,
    String? referencia,
    int? idUsuario,
    int? idTipoPagamento,
    String? statusPedido,
    double? total,
    double? valorPago,
    double? troco,
    String? pontoReferencia,
    String? observacoes,
    DateTime? dataPedido,
    DateTime? dataFinalizacao,
    List<ItemPedidoModel>? itensProduto,
    List<ItemPedidoServicoModel>? itensServico,
    int? idCliente,

  }) {
    return PedidoModel(
      idPedido: idPedido ?? this.idPedido,
      referencia: referencia ?? this.referencia,
      idUsuario: idUsuario ?? this.idUsuario,
      idTipoPagamento: idTipoPagamento ?? this.idTipoPagamento,
      statusPedido: statusPedido ?? this.statusPedido,
      total: total ?? this.total,
      valorPago: valorPago ?? this.valorPago,
      troco: troco ?? this.troco,
      pontoReferencia: pontoReferencia ?? this.pontoReferencia,
      observacoes: observacoes ?? this.observacoes,
      dataPedido: dataPedido ?? this.dataPedido,
      dataFinalizacao: dataFinalizacao ?? this.dataFinalizacao,
      itensProduto: itensProduto ?? this.itensProduto,
      itensServico: itensServico ?? this.itensServico,
      idCliente: idCliente ?? this.idCliente,
      
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REQUEST DTOs
// ═══════════════════════════════════════════════════════════════════════════

/// Espelha ItemPedidoRequestDTO Java.
class ItemPedidoRequestModel {
  final int idProduto;
  final int quantidade;

  const ItemPedidoRequestModel({
    required this.idProduto,
    required this.quantidade,
  });

  Map<String, dynamic> toJson() => {
        'idProduto': idProduto,
        'quantidade': quantidade,
      };
}

/// Espelha ItemServicoRequestDTO Java.
class ItemServicoRequestModel {
  final int idServico;
  final int quantidade;
  final String? observacoes;

  const ItemServicoRequestModel({
    required this.idServico,
    required this.quantidade,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        'idServico': idServico,
        'quantidade': quantidade,
        'observacoes': observacoes,
      };
}

/// Espelha PedidoRequestDTO Java.
class PedidoRequestModel {
  final int idUsuario;
  final int idTipoPagamento;
  final String? pontoReferencia;
  final String? observacoes;
  final List<ItemPedidoRequestModel> itensProduto;
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
        'idUsuario': idUsuario,
        'idTipoPagamento': idTipoPagamento,
        'pontoReferencia': pontoReferencia,
        'observacoes': observacoes,
        'itensProduto': itensProduto.map((e) => e.toJson()).toList(),
        'itensServico': itensServico.map((e) => e.toJson()).toList(),
      };
}

/// Espelha EditarItemRequestDTO Java.
class EditarItemRequestModel {
  final int novaQuantidade;

  const EditarItemRequestModel({required this.novaQuantidade});

  Map<String, dynamic> toJson() => {'novaQuantidade': novaQuantidade};
}

/// Espelha FinalizarPedidoRequestDTO Java.

class FinalizarPedidoRequestModel {
  final int idTipoPagamento;
  final double valorPago;
  final String? observacoes;
  final int? idCliente;                  // ← empresa seleccionada
  final String? nomeClienteSingular;     // ← cliente singular (não cadastrado)
  final String? apelidoClienteSingular;  // ← cliente singular (não cadastrado)

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
/// Espelha CancelamentoPedidoRequestDTO Java.
class CancelamentoPedidoRequestModel {
  final int idUsuarioCancelou;
  final String? motivo;

  const CancelamentoPedidoRequestModel({
    required this.idUsuarioCancelou,
    this.motivo,
  });

  Map<String, dynamic> toJson() => {
        'idUsuarioCancelou': idUsuarioCancelou,
        'motivo': motivo,
      };
}

