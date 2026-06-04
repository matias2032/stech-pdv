package com.stechengenharia.pdv_backend.cliente.dto;

import jakarta.validation.constraints.*;

public record ClienteRequestDTO(

    @Size(max = 250, message = "Nome deve ter no máximo 250 caracteres")
    String nome,

    @Size(max = 250, message = "Apelido deve ter no máximo 250 caracteres")
    String apelido,

    @Email(message = "E-mail inválido")
    @Size(max = 250)
    String email,

    @Size(max = 250, message = "NUIT deve ter no máximo 250 caracteres")
    String nuit,

    @Size(max = 250, message = "Contacto deve ter no máximo 250 caracteres")
    String contacto,

    @Size(max = 250, message = "Morada deve ter no máximo 250 caracteres")
    String morada,

    @NotNull(message = "O perfil do cliente é obrigatório")
    Long idPerfil
) {}