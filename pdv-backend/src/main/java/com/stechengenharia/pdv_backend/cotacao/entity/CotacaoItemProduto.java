package com.stechengenharia.pdv_backend.cotacao.entity;

import com.stechengenharia.pdv_backend.produto.entity.Produto;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "cotacao_item_produto")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CotacaoItemProduto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_item_cotacao_produto")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_cotacao", nullable = false)
    private Cotacao cotacao;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_produto", nullable = false)
    private Produto produto;

    @Column(name = "quantidade", nullable = false)
    private Integer quantidade;

    @Column(name = "preco_unitario", nullable = false, precision = 12, scale = 2)
    private BigDecimal precoUnitario;

    @Column(name = "observacoes", columnDefinition = "text")
    private String observacoes;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = Instant.now();
    }

    // subtotal calculado em memória (no DB é coluna GENERATED)
    public BigDecimal getSubtotal() {
        if (quantidade == null || precoUnitario == null) return BigDecimal.ZERO;
        return precoUnitario.multiply(BigDecimal.valueOf(quantidade));
    }
}