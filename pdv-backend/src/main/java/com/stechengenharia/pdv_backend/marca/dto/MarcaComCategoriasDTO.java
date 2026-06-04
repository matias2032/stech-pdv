package com.stechengenharia.pdv_backend.marca.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MarcaComCategoriasDTO {
    private Integer idMarca;
    private String nomeMarca;
    private List<CategoriaSimplificadaDTO> categorias;
}