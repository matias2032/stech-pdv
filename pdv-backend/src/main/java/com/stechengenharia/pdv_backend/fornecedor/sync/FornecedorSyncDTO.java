package com.stechengenharia.pdv_backend.fornecedor.sync;

import java.time.Instant;

public record FornecedorSyncDTO(
        Long idFornecedor,
        String nome,
        String email,
        String nuit,
        String contacto,
        String morada,
        String syncStatus,
        boolean deleted,
        Long version,
        Instant updatedAt
) {}