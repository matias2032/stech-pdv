package com.stechengenharia.pdv_backend.cliente.sync;

import java.time.Instant;

public record ClienteSyncDTO(
    Long idCliente,
    String nome,
    String apelido,
    String email,
    String nuit,
    String contacto,
    String morada,
    Long idPerfil,          // apenas o ID — evita dependência circular com PerfilCliente
    String syncStatus,
    boolean deleted,
    Long version,
    Instant updatedAt
) {}