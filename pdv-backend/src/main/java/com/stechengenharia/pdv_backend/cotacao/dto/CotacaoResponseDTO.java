package com.stechengenharia.pdv_backend.cotacao.dto;

import com.stechengenharia.pdv_backend.cotacao.entity.Cotacao;
import com.stechengenharia.pdv_backend.cotacao.entity.CotacaoItemProduto;
import com.stechengenharia.pdv_backend.cotacao.entity.CotacaoItemServico;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public final class CotacaoResponseDTO {

    private CotacaoResponseDTO() {}

    // ── Item de produto ───────────────────────────────────────────────
    public record ItemProduto(
            Long idItemCotacaoProduto,
            Integer idProduto,
            String nomeProduto,
            Integer quantidade,
            BigDecimal precoUnitario,
            BigDecimal subtotal,
            String observacoes
    ) {
        public ItemProduto(CotacaoItemProduto item) {
            this(
                    item.getId(),
                    item.getProduto().getIdProduto(),
                    item.getProduto().getNomeProduto(),
                    item.getQuantidade(),
                    item.getPrecoUnitario(),
                    item.getSubtotal(),
                    item.getObservacoes()
            );
        }
    }


// ── Item de serviço ───────────────────────────────────────────────
public record ItemServico(
        Long idItemCotacaoServico,
        Long idServico,       // ← manter Long aqui
        String nomeServico,
        Integer quantidade,
        BigDecimal precoUnitario,
        BigDecimal subtotal,
        String observacoes
) {
    public ItemServico(CotacaoItemServico item) {
        this(
                item.getId(),
                // converte para Long independentemente do tipo devolvido pelo getter
                item.getServico().getIdServico() != null
                        ? Long.valueOf(item.getServico().getIdServico().longValue())
                        : null,
                item.getServico().getNomeServico(),
                item.getQuantidade(),
                item.getPrecoUnitario(),
                item.getSubtotal(),
                item.getObservacoes()
        );
    }
}

    // ── Cotação completa ──────────────────────────────────────────────
    public record Detalhe(
            Long idCotacao,
            String referencia,
            Long idCliente,
            String nomeCliente,
                 String nomeClienteSingular,      // ← novo
        String apelidoClienteSingular,   // ← novo
            Long idUsuario,
            String nomeUsuario,
            String statusCotacao,
            BigDecimal total,
            LocalDate validadeAte,
            String observacoes,
            Integer idPedidoConvertido,
            List<ItemProduto> itensProduto,
            List<ItemServico> itensServico,
            Instant createdAt,
            Instant updatedAt
    ) {
        public Detalhe(Cotacao c) {
            this(
                    c.getId(),
                    c.getReferencia(),

                    c.getCliente() != null ? c.getCliente().getId() : null,
                    c.getCliente() != null
                            ? (c.getCliente().getNome() + " " +
                               (c.getCliente().getApelido() != null
                                       ? c.getCliente().getApelido() : "")).trim()
                            : null,
     c.getNomeClienteSingular(),       // ← novo
                c.getApelidoClienteSingular(),    // ← novo
                    c.getUsuario().getId(),
                    (c.getUsuario().getNome() + " " +
                     (c.getUsuario().getApelido() != null
                             ? c.getUsuario().getApelido() : "")).trim(),

                    c.getStatusCotacao(),
                    c.getTotal(),
                    c.getValidadeAte(),
                    c.getObservacoes(),

                    c.getPedidoConvertido() != null
                            ? c.getPedidoConvertido().getIdPedido() : null,

                    c.getItensProduto().stream()
                            .map(ItemProduto::new)
                            .toList(),

                    c.getItensServico().stream()
                            .map(ItemServico::new)
                            .toList(),

                    c.getCreatedAt(),
                    c.getUpdatedAt()
            );
        }
    }
}