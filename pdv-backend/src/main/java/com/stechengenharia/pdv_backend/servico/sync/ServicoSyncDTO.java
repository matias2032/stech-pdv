package com.stechengenharia.pdv_backend.servico.sync;

import java.math.BigDecimal;
import java.time.Instant;

public record ServicoSyncDTO(
    Integer idServico,
    String nomeServico,
    String descricao,
    BigDecimal precoUnitario,
    String unidade,
    Boolean ativo,
    String syncStatus,
    boolean deleted,
    Long version,
    Instant updatedAt
) {}