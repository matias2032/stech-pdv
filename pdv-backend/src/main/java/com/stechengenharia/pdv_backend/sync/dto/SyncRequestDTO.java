package com.stechengenharia.pdv_backend.sync.dto;

import jakarta.validation.Valid;
import lombok.Data;

import java.util.List;

@Data
public class SyncRequestDTO {

    @Valid
    private List<SyncOperacaoDTO> operacoes;
}