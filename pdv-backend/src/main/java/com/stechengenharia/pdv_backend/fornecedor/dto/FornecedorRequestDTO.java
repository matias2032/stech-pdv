package com.stechengenharia.pdv_backend.fornecedor.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record FornecedorRequestDTO(

        @Size(max = 250, message = "Nome deve ter no máximo 250 caracteres")
        String nome,

        @Email(message = "E-mail inválido")
        @Size(max = 250, message = "E-mail deve ter no máximo 250 caracteres")
        String email,

        @Size(max = 250, message = "NUIT deve ter no máximo 250 caracteres")
        String nuit,

        @NotBlank(message = "Contacto é obrigatório")
        @Size(max = 250, message = "Contacto deve ter no máximo 250 caracteres")
        String contacto,

        @Size(max = 250, message = "Morada deve ter no máximo 250 caracteres")
        String morada
) {}