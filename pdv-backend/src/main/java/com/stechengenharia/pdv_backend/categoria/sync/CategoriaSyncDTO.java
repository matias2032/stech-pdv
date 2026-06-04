package com.stechengenharia.pdv_backend.categoria.sync;

import java.time.Instant;

public record CategoriaSyncDTO(
    Integer idCategoria,
    String nomeCategoria,
    String descricao,
    String syncStatus,
    boolean deleted,
    Long version,
    Instant updatedAt       // era OffsetDateTime — alinhado com AuditableEntity
) {}