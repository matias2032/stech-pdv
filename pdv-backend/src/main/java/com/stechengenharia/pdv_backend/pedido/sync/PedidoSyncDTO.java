package com.stechengenharia.pdv_backend.pedido.sync;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;

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