package com.stechengenharia.pdv_backend.usuario.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record UsuarioRequestDTO(

    @NotBlank(message = "O nome é obrigatório")
    @Size(max = 250)
    String nome,

    @Size(max = 100)
    String apelido,

    @NotBlank(message = "O e-mail é obrigatório")
    @Email(message = "E-mail inválido")
    String email,

    @Size(max = 30)
    String telefone,

    // Enviado pelo Flutter; se null o backend usa a senha padrão
    String senha,

    @NotNull(message = "O perfil é obrigatório")
    Long idPerfil
) {}