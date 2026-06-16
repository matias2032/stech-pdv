package com.stechengenharia.pdv_backend.pedido.entity;

import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

@Entity
@Table(name = "pedido_credito_parcela")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class PedidoCreditoParcela extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_parcela")
    private Long idParcela;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_pedido", nullable = false)
    private Pedido pedido;

    @Column(name = "numero_parcela", nullable = false)
    private Integer numeroParcela;

    @Column(name = "valor_parcela", nullable = false, precision = 12, scale = 2)
    private BigDecimal valorParcela;

    @Column(name = "valor_pago", nullable = false, precision = 12, scale = 2)
    private BigDecimal valorPago = BigDecimal.ZERO;

    // saldo_parcela: GENERATED na BD
    @Column(name = "saldo_parcela", insertable = false, updatable = false,
            precision = 12, scale = 2)
    private BigDecimal saldoParcela;

    @Column(name = "data_vencimento", nullable = false)
    private LocalDate dataVencimento;

    @Column(name = "data_pagamento")
    private OffsetDateTime dataPagamento;

    @Column(name = "status_parcela", nullable = false, length = 20)
    private String statusParcela = "PENDENTE"; // PENDENTE | PARCIAL | PAGA | VENCIDA | CANCELADA

    @Column(name = "observacoes", columnDefinition = "TEXT")
    private String observacoes;
}