package com.stechengenharia.pdv_backend.pedido.sync;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;
import java.time.LocalDate;
import java.time.OffsetDateTime;

public record PedidoSyncDTO(
    Integer idPedido,
    String referencia,
    Integer idUsuario,
    Long idCliente,
    Integer idTipoPagamento,
    String statusPedido,
    BigDecimal total,
    BigDecimal valorPago,
    String pontoReferencia,
    String observacoes,
    LocalDateTime dataPedido,
    LocalDateTime dataFinalizacao,

    String nomeClienteSingular,      // ← novo
    String apelidoClienteSingular,   // ← novo


    // ── Crédito ─────────────────────────────────────────────
    String tipoVenda,
    String modalidadeCredito,
    String statusPagamento,
    Integer idDocumentoFacturaCredito,
    OffsetDateTime dataAberturaCredito,
    LocalDate dataVencimentoCredito,
    OffsetDateTime dataLiquidacaoCredito,
    String observacoesCredito,
    BigDecimal saldoDevedorCredito,

    List<ItemPedidoSyncDTO> itensProduto,
    List<ItemServicoPedidoSyncDTO> itensServico,
    String syncStatus,
    boolean deleted,
    Long version,
    Instant updatedAt
) {
    // DTOs internos — itens viajam embutidos no pedido
    public record ItemPedidoSyncDTO(
        Integer idItemPedido,
        Integer idProduto,
        Integer quantidade,
        BigDecimal precoUnitario,
        BigDecimal subtotal
    ) {}

    public record ItemServicoPedidoSyncDTO(
        Integer idItemServico,
        Integer idServico,
        Integer quantidade,
        BigDecimal precoUnitario,
        BigDecimal subtotal,
        String observacoes
    ) {}
}