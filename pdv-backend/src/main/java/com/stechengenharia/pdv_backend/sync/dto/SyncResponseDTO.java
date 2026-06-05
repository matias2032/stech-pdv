package com.stechengenharia.pdv_backend.sync.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class SyncResponseDTO {

    private int totalRecebidas;
    private int totalSucesso;
    private int totalErro;
    private List<SyncResultadoDTO> resultados;
}