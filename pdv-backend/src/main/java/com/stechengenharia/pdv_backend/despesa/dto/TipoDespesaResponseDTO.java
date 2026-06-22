package com.stechengenharia.pdv_backend.despesa.dto;

import com.stechengenharia.pdv_backend.despesa.entity.TipoDespesa;

public record TipoDespesaResponseDTO(
        Long idTipoDespesa,
        String nomeDespesa,
        String descricao,
        boolean deleted,
        String syncStatus,
        Long version
) {

    public static TipoDespesaResponseDTO from(TipoDespesa tipoDespesa) {
        return new TipoDespesaResponseDTO(
                tipoDespesa.getIdTipoDespesa(),
                tipoDespesa.getNomeDespesa(),
                tipoDespesa.getDescricao(),
                tipoDespesa.isDeleted(),
                tipoDespesa.getSyncStatus(),
                tipoDespesa.getVersion()
        );
    }
}