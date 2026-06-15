package com.stechengenharia.pdv_backend.cotacao.sync;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public record CotacaoSyncDTO(
        Long idCotacao,
        String referencia,
        Long idCliente,
        Long idUsuario,
        String statusCotacao,
        BigDecimal total,
        LocalDate validadeAte,
        String observacoes,
        Integer idPedidoConvertido,
        List<ItemProdutoSyncDTO> itensProduto,
        List<ItemServicoSyncDTO> itensServico,
        String syncStatus,
        boolean deleted,
        Long version,
        Instant updatedAt
) {
    public record ItemProdutoSyncDTO(
            Long idItemCotacaoProduto,
            Integer idProduto,
            Integer quantidade,
            BigDecimal precoUnitario,
            BigDecimal subtotal,
            String observacoes
    ) {}

    public record ItemServicoSyncDTO(
            Long idItemCotacaoServico,
            Long idServico,
            Integer quantidade,
            BigDecimal precoUnitario,
            BigDecimal subtotal,
            String observacoes
    ) {}
}