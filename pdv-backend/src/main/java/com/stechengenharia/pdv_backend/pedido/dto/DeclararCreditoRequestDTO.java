// DeclararCreditoRequestDTO.java
package com.stechengenharia.pdv_backend.pedido.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record DeclararCreditoRequestDTO(
    @NotNull Long idUsuario,
    @NotNull String modalidadeCredito,
    Long idCliente,          // ← NOVO campo
    LocalDate dataVencimento,
    String observacoesCredito,
    String codigoAt
) {}