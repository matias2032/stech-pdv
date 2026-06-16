package com.stechengenharia.pdv_backend.pedido.sync;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.OffsetDateTime;

public record PagamentoCreditoSyncDTO(
    Long idPagamentoCredito,
    String referencia,
    Integer idPedido,
    Long idParcela,
    Integer idTipoPagamento,
    Long idUsuario,
    Integer idDocumentoRecibo,
    BigDecimal valorPago,
    OffsetDateTime dataPagamento,
    String observacoes,
    String syncStatus,
    boolean deleted,
    Long version,
    Instant createdAt,
    Instant updatedAt
) {}