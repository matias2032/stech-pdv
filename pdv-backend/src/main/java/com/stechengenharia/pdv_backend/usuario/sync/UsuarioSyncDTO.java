package com.stechengenharia.pdv_backend.usuario.sync;


import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
import java.time.OffsetDateTime;

/**
 * DTO exclusivo para comunicação entre local e nuvem.
 * Nunca exposto ao Flutter.
 */
public record UsuarioSyncDTO(
        Long        localId,
        String      nome,
        String      apelido,
        String      email,
        String      telefone,
        String      senhaHash,      // hash, nunca a senha em texto-limpo
        Boolean     ativo,
        Boolean     deleted,
        String      syncStatus,
        Long        version,
        OffsetDateTime updatedAt
) {
public static UsuarioSyncDTO from(Usuario u) {
    return new UsuarioSyncDTO(
        u.getId(),
        u.getNome(),
        u.getApelido(),
        u.getEmail(),
        u.getTelefone(),
        u.getSenhaHash(),
        u.getAtivo(),
        u.isDeleted(), // 🟢 Corrigido para o padrão do Lombok (isDeleted)
        u.getSyncStatus(),
        u.getVersion(),
        u.getUpdatedAt() != null ? OffsetDateTime.ofInstant(u.getUpdatedAt(), java.time.ZoneOffset.UTC) : null // 🟢 Conversão segura aplicada
    );
}

public static UsuarioSyncDTO from(CloudUsuarioEntity cu) {
    return new UsuarioSyncDTO(
        cu.getLocalId(),
        cu.getNome(),
        cu.getApelido(),
        cu.getEmail(),
        cu.getTelefone(),
        cu.getSenhaHash(),
        cu.getAtivo(),
        cu.getDeleted(),
        null, // O campo syncStatus não existe em CloudUsuario (pode passar null se não for usado na nuvem)
        cu.getVersion(),
        cu.getUpdatedAt()
    );
}
}