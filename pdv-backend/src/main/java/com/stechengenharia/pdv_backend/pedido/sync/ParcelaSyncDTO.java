package com.stechengenharia.pdv_backend.pedido.sync;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;

public record ParcelaSyncDTO(
    Long idParcela,
    Integer idPedido,
    Integer numeroParcela,
    BigDecimal valorParcela,
    BigDecimal valorPago,
    BigDecimal saldoParcela,
    LocalDate dataVencimento,
    OffsetDateTime dataPagamento,
    String statusParcela,
    String observacoes,
    String syncStatus,
    boolean deleted,
    Long version,
    Instant createdAt,
    Instant updatedAt
) {}