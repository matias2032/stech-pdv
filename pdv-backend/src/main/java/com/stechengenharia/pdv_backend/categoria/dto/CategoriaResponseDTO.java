package com.stechengenharia.pdv_backend.categoria.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data @NoArgsConstructor @AllArgsConstructor
public class CategoriaResponseDTO {
    private Integer idCategoria;
    private String nomeCategoria;
    private String descricao;
    private List<Integer> marcas; // ← IDs das marcas associadas
}