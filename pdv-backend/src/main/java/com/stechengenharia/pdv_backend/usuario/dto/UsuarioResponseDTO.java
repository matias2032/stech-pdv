// Substituir o record completo:

package com.stechengenharia.pdv_backend.usuario.dto;

import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
import java.time.OffsetDateTime;

public record UsuarioResponseDTO(
    Long id,
    String nome,
    String apelido,
    String email,
    String telefone,
    Boolean ativo,
    Boolean primeiraSenha,
    String nomePerfil,
    OffsetDateTime criadoEm,
    OffsetDateTime atualizadoEm
) {
public UsuarioResponseDTO(Usuario u) {
    this(
        u.getId(),
        u.getNome(),
        u.getApelido(),
        u.getEmail(),
        u.getTelefone(),
        u.getAtivo(),
        u.getPrimeiraSenha(),
        u.getPerfil() != null ? u.getPerfil().getNome() : "Sem perfil",
        u.getCreatedAt() != null ? OffsetDateTime.ofInstant(u.getCreatedAt(), java.time.ZoneOffset.UTC) : null,
        u.getUpdatedAt() != null ? OffsetDateTime.ofInstant(u.getUpdatedAt(), java.time.ZoneOffset.UTC) : null
    );
}
}