package com.stechengenharia.pdv_backend.despesa.dto;

import com.stechengenharia.pdv_backend.despesa.entity.Despesa;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public record DespesaResponseDTO(

        Long idDespesa,

        Long idFornecedor,
        String nomeFornecedor,
        String nuitFornecedor,

        String descricao,
        BigDecimal valorGasto,
        OffsetDateTime dataDespesa,

        boolean deleted,
        String syncStatus,
        Long version
) {

    public static DespesaResponseDTO from(Despesa despesa) {
        var fornecedor = despesa.getFornecedor();

        return new DespesaResponseDTO(
                despesa.getIdDespesa(),

                fornecedor != null ? fornecedor.getId() : null,
                fornecedor != null ? fornecedor.getNome() : null,
                fornecedor != null ? fornecedor.getNuit() : null,

                despesa.getDescricao(),
                despesa.getValorGasto(),
                despesa.getDataDespesa(),

                despesa.isDeleted(),
                despesa.getSyncStatus(),
                despesa.getVersion()
        );
    }
}