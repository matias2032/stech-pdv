// ParcelaResponseDTO.java
package com.stechengenharia.pdv_backend.pedido.dto;

import com.stechengenharia.pdv_backend.pedido.entity.PedidoCreditoParcela;
import java.math.BigDecimal;
import java.time.LocalDate;

public record ParcelaResponseDTO(
    Long idParcela,
    Integer numeroParcela,
    BigDecimal valorParcela,
    BigDecimal valorPago,
    BigDecimal saldoParcela,
    LocalDate dataVencimento,
    String statusParcela
) {
    public static ParcelaResponseDTO from(PedidoCreditoParcela p) {
        return new ParcelaResponseDTO(
            p.getIdParcela(), p.getNumeroParcela(),
            p.getValorParcela(), p.getValorPago(), p.getSaldoParcela(),
            p.getDataVencimento(), p.getStatusParcela()
        );
    }
}