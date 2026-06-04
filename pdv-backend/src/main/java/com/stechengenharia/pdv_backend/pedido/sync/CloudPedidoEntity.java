package com.stechengenharia.pdv_backend.pedido.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;

@Entity
@Table(name = "pedido")
@Getter @Setter @NoArgsConstructor
public class CloudPedidoEntity {

    @Id
    @Column(name = "id_pedido")
    private Integer idPedido;               // SEM @GeneratedValue

    @Column(name = "referencia", nullable = false, unique = true, length = 50)
    private String referencia;

    @Column(name = "id_usuario", nullable = false)
    private Integer idUsuario;

    @Column(name = "id_cliente")
    private Long idCliente;

    @Column(name = "id_tipo_pagamento", nullable = false)
    private Integer idTipoPagamento;

    @Column(name = "status_pedido", nullable = false, length = 50)
    private String statusPedido;

    @Column(name = "total", nullable = false, precision = 12, scale = 2)
    private BigDecimal total;

    @Column(name = "valor_pago", nullable = false, precision = 12, scale = 2)
    private BigDecimal valorPago;

    @Column(name = "ponto_referencia", columnDefinition = "TEXT")
    private String pontoReferencia;

    @Column(name = "observacoes", columnDefinition = "TEXT")
    private String observacoes;

    @Column(name = "data_pedido", nullable = false)
    private LocalDateTime dataPedido;

    @Column(name = "data_finalizacao")
    private LocalDateTime dataFinalizacao;

    @Column(name = "deleted", nullable = false)
    private boolean deleted = false;

    @Column(name = "sync_status", length = 20, nullable = false)
    private String syncStatus = "SYNCED";

    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}