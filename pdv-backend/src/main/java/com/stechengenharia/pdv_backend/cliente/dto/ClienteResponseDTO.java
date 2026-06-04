package com.stechengenharia.pdv_backend.cliente.dto;

import com.stechengenharia.pdv_backend.cliente.entity.Cliente;

public record ClienteResponseDTO(
    Long id,
    String nome,
    String apelido,
    String email,
    String nuit,
    String contacto,
    String morada,
    Long idPerfil,
    String nomePerfil
) {
    public ClienteResponseDTO(Cliente c) {
        this(
            c.getId(),
            c.getNome(),
            c.getApelido(),
            c.getEmail(),
            c.getNuit(),
            c.getContacto(),
            c.getMorada(),
            c.getPerfil() != null ? c.getPerfil().getId()   : null,
            c.getPerfil() != null ? c.getPerfil().getNome() : "Sem perfil"
        );
    }
}