package com.stechengenharia.pdv_backend.despesa.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record DespesaRequestDTO(

        Long idFornecedor,

        @NotBlank(message = "A descrição da despesa é obrigatória")
        @Size(max = 500, message = "A descrição deve ter no máximo 500 caracteres")
        String descricao,

        @NotNull(message = "O valor gasto é obrigatório")
        @DecimalMin(value = "0.01", message = "O valor gasto deve ser maior que zero")
        BigDecimal valorGasto
) {}