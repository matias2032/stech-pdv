package com.stechengenharia.pdv_backend.pedido.dto;

import jakarta.validation.constraints.*;  
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor

public class EditarItemRequestDTO {

    @NotNull @Min(value = 1, message = "A quantidade mínima é 1")
    public Integer novaQuantidade;
}
