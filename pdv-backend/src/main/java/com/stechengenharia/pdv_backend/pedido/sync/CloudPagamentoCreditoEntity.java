package com.stechengenharia.pdv_backend.pedido.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.OffsetDateTime;

@Entity
@Table(name = "pedido_credito_pagamento")
@Getter
@Setter
@NoArgsConstructor
public class CloudPagamentoCreditoEntity {

    @Id
    @Column(name = "id_pagamento_credito")
    private Long idPagamentoCredito; // SEM @GeneratedValue — vem da loja

    @Column(name = "referencia", nullable = false, unique = true, length = 50)
    private String referencia;

    @Column(name = "id_pedido", nullable = false)
    private Integer idPedido;

    @Column(name = "id_parcela")
    private Long idParcela;

    @Column(name = "id_tipo_pagamento", nullable = false)
    private Integer idTipoPagamento;

    @Column(name = "id_usuario", nullable = false)
    private Long idUsuario;

    @Column(name = "id_documento_recibo", nullable = false, unique = true)
    private Integer idDocumentoRecibo;

    @Column(name = "valor_pago", nullable = false, precision = 12, scale = 2)
    private BigDecimal valorPago;

    @Column(name = "data_pagamento", nullable = false)
    private OffsetDateTime dataPagamento;

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