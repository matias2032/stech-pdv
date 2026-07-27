package com.stechengenharia.pdv_backend.documento.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

// DEPOIS
public record ExtractoDocumentalClienteResponseDTO(
    Long idCliente,
    String nomeCliente,
    int totalDocumentos,
    BigDecimal somaTotal,
    BigDecimal somaLiquida,
    List<LinhaDocumentalDTO> linhas
) {
    public record LinhaDocumentalDTO(
        Integer idDocumento,
        String referencia,
        String tipoDocumento, // "FAT" ou "VD"
        Integer idPedido,
        String referenciaPedido,
        OffsetDateTime emitidoEm,
        BigDecimal valorTotal,
        /** Soma de NDB - soma de NCR associadas a este documento. Pode ser negativo. */
        BigDecimal valorAjuste,
        /** valorTotal + valorAjuste — valor já líquido de notas de crédito/débito. */
        BigDecimal valorLiquido
    ) {}
}