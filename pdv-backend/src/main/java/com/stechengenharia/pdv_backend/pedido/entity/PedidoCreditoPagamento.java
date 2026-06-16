package com.stechengenharia.pdv_backend.pedido.entity;

import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "pedido_credito_pagamento")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class PedidoCreditoPagamento extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_pagamento_credito")
    private Long idPagamentoCredito;

    @Column(name = "referencia", nullable = false, unique = true, length = 50)
    private String referencia;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_pedido", nullable = false)
    private Pedido pedido;

    // Parcela é opcional (pagamento livre ou com parcelas)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_parcela")
    private PedidoCreditoParcela parcela;

    @Column(name = "id_tipo_pagamento", nullable = false)
    private Integer idTipoPagamento;

    @Column(name = "id_usuario", nullable = false)
    private Long idUsuario;

    // Recibo emitido para este pagamento
    @Column(name = "id_documento_recibo", nullable = false, unique = true)
    private Integer idDocumentoRecibo;

    @Column(name = "valor_pago", nullable = false, precision = 12, scale = 2)
    private BigDecimal valorPago;

    @Column(name = "data_pagamento", nullable = false)
    private OffsetDateTime dataPagamento;

    @Column(name = "observacoes", columnDefinition = "TEXT")
    private String observacoes;
}