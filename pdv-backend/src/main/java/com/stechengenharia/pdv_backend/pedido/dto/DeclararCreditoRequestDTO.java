package com.stechengenharia.pdv_backend.pedido.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record DeclararCreditoRequestDTO(
    @NotNull Long idUsuario,
    @NotNull String modalidadeCredito,

    Long idCliente,
    String nomeClienteSingular,
    String apelidoClienteSingular,

    LocalDate dataVencimento,
    String observacoesCredito,
    String codigoAt
) {}