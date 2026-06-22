package com.stechengenharia.pdv_backend.despesa.sync;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.OffsetDateTime;

public record DespesaSyncDTO(
        Long idDespesa,
        Long idFornecedor,
        Long idTipoDespesa,
        String descricao,
        BigDecimal valorGasto,
        OffsetDateTime dataDespesa,
        String syncStatus,
        boolean deleted,
        Long version,
        Instant updatedAt
) {}