package com.stechengenharia.pdv_backend.despesa.dto;

import jakarta.validation.constraints.Size;

public record DespesaExclusaoRequestDTO(

        @Size(max = 500, message = "O motivo da exclusão deve ter no máximo 500 caracteres")
        String motivoExclusao

) {}