package com.stechengenharia.pdv_backend.despesa.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TipoDespesaRequestDTO(

        @NotBlank(message = "O nome do tipo de despesa é obrigatório")
        @Size(max = 150, message = "O nome deve ter no máximo 150 caracteres")
        String nomeDespesa,

        @Size(max = 500, message = "A descrição deve ter no máximo 500 caracteres")
        String descricao
) {}