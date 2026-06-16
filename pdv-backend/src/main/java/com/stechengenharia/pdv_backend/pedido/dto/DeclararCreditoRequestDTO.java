// DeclararCreditoRequestDTO.java
package com.stechengenharia.pdv_backend.pedido.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record DeclararCreditoRequestDTO(
    @NotNull Long idUsuario,
    @NotNull String modalidadeCredito,   // SEM_PARCELAS | PARCELADO
    LocalDate dataVencimento,            // para SEM_PARCELAS
    String observacoesCredito,
    String codigoAt                      // para emissão da factura
) {}