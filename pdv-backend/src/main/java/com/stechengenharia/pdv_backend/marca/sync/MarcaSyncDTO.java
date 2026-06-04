package com.stechengenharia.pdv_backend.marca.sync;

import java.time.Instant;

public record MarcaSyncDTO(
    Integer idMarca,
    String nomeMarca,
    String syncStatus,
    boolean deleted,
    Long version,
    Instant updatedAt   // era OffsetDateTime
) {}