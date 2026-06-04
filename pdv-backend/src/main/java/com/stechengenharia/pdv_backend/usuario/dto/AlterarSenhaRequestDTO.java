package com.stechengenharia.pdv_backend.usuario.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AlterarSenhaRequestDTO(

    @NotBlank(message = "A senha actual é obrigatória")
    String senhaAtual,

    @NotBlank(message = "A nova senha é obrigatória")
    @Size(min = 8, message = "A nova senha deve ter pelo menos 8 caracteres")
    String novaSenha
) {}