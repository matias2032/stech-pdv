package com.stechengenharia.pdv_backend.marca.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MarcaResponseDTO {
    private Integer idMarca;
    private String nomeMarca;
}