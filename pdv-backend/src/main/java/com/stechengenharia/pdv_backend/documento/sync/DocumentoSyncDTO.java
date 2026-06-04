package com.stechengenharia.pdv_backend.documento.sync;

import java.time.Instant;
import java.time.OffsetDateTime;

public record DocumentoSyncDTO(
    Integer idDocumento,
    Integer idTipoDocumento,    // só o ID — evita dependência circular
    Integer idPedido,
    String referencia,
    Integer numeroSeq,
    Integer ano,
    String codigoAt,
    Long idUsuario,
    OffsetDateTime emitidoEm,
    Boolean anulado,
    String motivoAnulacao,
    String syncStatus,
    boolean deleted,
    Long version,
    Instant updatedAt
) {}