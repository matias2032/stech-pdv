// ExtractoClienteResponseDTO.java
package com.stechengenharia.pdv_backend.pedido.dto;

import java.math.BigDecimal;
import java.util.List;

public record ExtractoClienteResponseDTO(
    Long idCliente,
    BigDecimal totalDivida,
    BigDecimal totalPago,
    BigDecimal saldoDevedor,
    List<ExtractoPedidoDTO> pedidos
) {
    public record ExtractoPedidoDTO(
        Integer idPedido,
        String referencia,
        BigDecimal total,
        BigDecimal valorPago,
        BigDecimal saldoDevedor,
        String statusPagamento,
        Integer idDocumentoFactura
    ) {}
}