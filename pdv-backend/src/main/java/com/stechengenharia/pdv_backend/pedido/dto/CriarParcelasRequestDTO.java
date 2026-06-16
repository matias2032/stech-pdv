// CriarParcelasRequestDTO.java
package com.stechengenharia.pdv_backend.pedido.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record CriarParcelasRequestDTO(
    @NotNull List<ParcelaItemDTO> parcelas
) {
    public record ParcelaItemDTO(
        @NotNull @Min(1) Integer numeroParcela,
        @NotNull BigDecimal valorParcela,
        @NotNull LocalDate dataVencimento
    ) {}
}