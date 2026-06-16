package com.stechengenharia.pdv_backend.pedido.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;

@Entity
@Table(name = "pedido_credito_parcela")
@Getter
@Setter
@NoArgsConstructor
public class CloudParcelaEntity {

    @Id
    @Column(name = "id_parcela")
    private Long idParcela; // SEM @GeneratedValue — vem da loja

    @Column(name = "id_pedido", nullable = false)
    private Integer idPedido;

    @Column(name = "numero_parcela", nullable = false)
    private Integer numeroParcela;

    @Column(name = "valor_parcela", nullable = false, precision = 12, scale = 2)
    private BigDecimal valorParcela;

    @Column(name = "valor_pago", nullable = false, precision = 12, scale = 2)
    private BigDecimal valorPago = BigDecimal.ZERO;

    // GENERATED na BD — read-only
    @Column(name = "saldo_parcela", insertable = false, updatable = false,
            precision = 12, scale = 2)
    private BigDecimal saldoParcela;

    @Column(name = "data_vencimento", nullable = false)
    private LocalDate dataVencimento;

    @Column(name = "data_pagamento")
    private OffsetDateTime dataPagamento;

    @Column(name = "status_parcela", nullable = false, length = 20)
    private String statusParcela = "PENDENTE";

    @Column(name = "observacoes", columnDefinition = "TEXT")
    private String observacoes;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "deleted", nullable = false)
    private boolean deleted = false;

    @Column(name = "sync_status", length = 20, nullable = false)
    private String syncStatus = "SYNCED";

    @Version
    @Column(name = "version", nullable = false)
    private Long version;
}