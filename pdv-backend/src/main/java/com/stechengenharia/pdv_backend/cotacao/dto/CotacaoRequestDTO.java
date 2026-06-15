package com.stechengenharia.pdv_backend.cotacao.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;

public final class CotacaoRequestDTO {

    private CotacaoRequestDTO() {}

    // ── POST /api/cotacoes ────────────────────────────────────────────
    public record Criar(

            Long idCliente,

            @NotNull(message = "O utilizador é obrigatório.")
            Long idUsuario,

            @Future(message = "A validade deve ser uma data futura.")
            LocalDate validadeAte,

            String observacoes
    ) {}

    // ── PUT /api/cotacoes/{id} ────────────────────────────────────────
    public record Atualizar(

            Long idCliente,

            @Future(message = "A validade deve ser uma data futura.")
            LocalDate validadeAte,

            String observacoes,

            String statusCotacao
    ) {}

    // ── POST /api/cotacoes/{id}/produtos ──────────────────────────────
    public record AdicionarProduto(

            @NotNull(message = "O produto é obrigatório.")
            Integer idProduto,

            @NotNull(message = "A quantidade é obrigatória.")
            @Min(value = 1, message = "A quantidade mínima é 1.")
            Integer quantidade,

            @DecimalMin(value = "0.0", inclusive = true, message = "O preço não pode ser negativo.")
            BigDecimal precoUnitario,

            String observacoes
    ) {}

    // ── POST /api/cotacoes/{id}/servicos ──────────────────────────────
    public record AdicionarServico(

            @NotNull(message = "O serviço é obrigatório.")
            Long idServico,

            @NotNull(message = "A quantidade é obrigatória.")
            @Min(value = 1, message = "A quantidade mínima é 1.")
            Integer quantidade,

            @DecimalMin(value = "0.0", inclusive = true, message = "O preço não pode ser negativo.")
            BigDecimal precoUnitario,

            String observacoes
    ) {}

    // ── PUT /api/cotacoes/{id}/produtos/{idItem}
    // ── PUT /api/cotacoes/{id}/servicos/{idItem} ──────────────────────
    public record AtualizarItem(

            @NotNull(message = "A quantidade é obrigatória.")
            @Min(value = 1, message = "A quantidade mínima é 1.")
            Integer quantidade,

            @DecimalMin(value = "0.0", inclusive = true, message = "O preço não pode ser negativo.")
            BigDecimal precoUnitario,

            String observacoes
    ) {}

    // ── POST /api/cotacoes/{id}/converter-em-pedido ───────────────────
    public record ConverterEmPedido(

            @NotNull(message = "O tipo de pagamento é obrigatório.")
            Integer idTipoPagamento,

            BigDecimal valorPago,

            String observacoes
    ) {}
}