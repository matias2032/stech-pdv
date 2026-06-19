package com.stechengenharia.pdv_backend.pedido.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.LocalDate;
import java.time.OffsetDateTime;

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

    // ── Crédito ─────────────────────────────────────────────

@Column(name = "tipo_venda", nullable = false, length = 20)
private String tipoVenda = "IMEDIATA";

@Column(name = "modalidade_credito", length = 20)
private String modalidadeCredito;

@Column(name = "status_pagamento", nullable = false, length = 20)
private String statusPagamento = "PENDENTE";

@Column(name = "id_documento_factura_credito")
private Integer idDocumentoFacturaCredito;

@Column(name = "data_abertura_credito")
private OffsetDateTime dataAberturaCredito;

@Column(name = "data_vencimento_credito")
private LocalDate dataVencimentoCredito;

@Column(name = "data_liquidacao_credito")
private OffsetDateTime dataLiquidacaoCredito;

@Column(name = "observacoes_credito", columnDefinition = "TEXT")
private String observacoesCredito;

// GENERATED na BD — read-only
@Column(name = "saldo_devedor_credito", insertable = false, updatable = false,
        precision = 12, scale = 2)
private BigDecimal saldoDevedorCredito;

    @Column(name = "deleted", nullable = false)
    private boolean deleted = false;

    @Column(name = "sync_status", length = 20, nullable = false)
    private String syncStatus = "SYNCED";

    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "nome_cliente_singular", length = 150)
private String nomeClienteSingular;

@Column(name = "apelido_cliente_singular", length = 150)
private String apelidoClienteSingular;
}