// PagamentoCreditoResponseDTO.java
package com.stechengenharia.pdv_backend.pedido.dto;

import com.stechengenharia.pdv_backend.pedido.entity.PedidoCreditoPagamento;
import java.math.BigDecimal;
import java.time.OffsetDateTime;


public record PagamentoCreditoResponseDTO(
    Long idPagamentoCredito,
    String referencia,
    Long idPedido,
    Integer idTipoPagamento,
    Long idUsuario,
    BigDecimal valorPago,
    OffsetDateTime dataPagamento,
    Integer idDocumentoRecibo,
    Long idParcela
) {
    public static PagamentoCreditoResponseDTO from(PedidoCreditoPagamento p) {
        return new PagamentoCreditoResponseDTO(
            p.getIdPagamentoCredito(),
            p.getReferencia(),
            p.getPedido().getIdPedido().longValue(),
            p.getIdTipoPagamento(),
            p.getIdUsuario(),
            p.getValorPago(),
            p.getDataPagamento(),
            p.getIdDocumentoRecibo(),
            p.getParcela() != null ? p.getParcela().getIdParcela() : null
        );
    }
}