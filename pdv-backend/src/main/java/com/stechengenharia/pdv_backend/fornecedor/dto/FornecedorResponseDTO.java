package com.stechengenharia.pdv_backend.fornecedor.dto;

import com.stechengenharia.pdv_backend.fornecedor.entity.Fornecedor;

public record FornecedorResponseDTO(
        Long id,
        String nome,
        String email,
        String nuit,
        String contacto,
        String morada
) {
    public FornecedorResponseDTO(Fornecedor f) {
        this(
                f.getId(),
                f.getNome(),
                f.getEmail(),
                f.getNuit(),
                f.getContacto(),
                f.getMorada()
        );
    }
}