package com.stechengenharia.pdv_backend.despesa.dto;

import com.stechengenharia.pdv_backend.despesa.entity.Despesa;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public record DespesaResponseDTO(

        Long idDespesa,

        Long idFornecedor,
        String nomeFornecedor,
        String nuitFornecedor,

        Long idTipoDespesa,
        String nomeTipoDespesa,

        String descricao,
        BigDecimal valorGasto,
        OffsetDateTime dataDespesa,
        String motivoExclusao,

        boolean deleted,
        String syncStatus,
        Long version
) {

    public static DespesaResponseDTO from(Despesa despesa) {
        var fornecedor = despesa.getFornecedor();
        var tipoDespesa = despesa.getTipoDespesa();

        return new DespesaResponseDTO(
                despesa.getIdDespesa(),

                fornecedor != null ? fornecedor.getId() : null,
                fornecedor != null ? fornecedor.getNome() : null,
                fornecedor != null ? fornecedor.getNuit() : null,

                tipoDespesa != null ? tipoDespesa.getIdTipoDespesa() : null,
                tipoDespesa != null ? tipoDespesa.getNomeDespesa() : null,

                despesa.getDescricao(),
                despesa.getValorGasto(),
                despesa.getDataDespesa(),
                despesa.getMotivoExclusao(),

                despesa.isDeleted(),
                despesa.getSyncStatus(),
                despesa.getVersion()
        );
    }
}