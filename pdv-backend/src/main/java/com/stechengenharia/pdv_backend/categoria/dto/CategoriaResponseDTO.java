package com.stechengenharia.pdv_backend.categoria.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategoriaResponseDTO {
    
    private Integer idCategoria;
    private String nomeCategoria;
    private String descricao;
}