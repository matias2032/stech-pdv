package com.stechengenharia.pdv_backend.pedido.dto;

import java.math.BigDecimal;

public record DevolucaoResponseDTO(
        Integer idNotaCredito,
        String referenciaNotaCredito,
        Integer idPedidoOrigem,
        BigDecimal valorCreditado,
        String motivo
) {}