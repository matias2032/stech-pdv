package com.stechengenharia.pdv_backend.produto.sync;

import java.math.BigDecimal;
import java.time.Instant;

public record ProdutoSyncDTO(
    Integer idProduto,
    String nomeProduto,
    String descricao,
    BigDecimal preco,
    BigDecimal precoPromocional,
    Integer quantidadeEstoque,
    Short ativo,
    String syncStatus,
    boolean deleted,
    Long version,
    Instant updatedAt
) {}