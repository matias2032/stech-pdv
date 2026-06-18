package com.stechengenharia.pdv_backend.documento.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

public record ExtractoDocumentalClienteResponseDTO(
    Long idCliente,
    String nomeCliente,
    int totalDocumentos,
    BigDecimal somaTotal,
    List<LinhaDocumentalDTO> linhas
) {
    public record LinhaDocumentalDTO(
        Integer idDocumento,
        String referencia,
        String tipoDocumento, // "FAT" ou "VD"
        Integer idPedido,
        String referenciaPedido,
        OffsetDateTime emitidoEm,
        BigDecimal valorTotal
    ) {}
}