package com.stechengenharia.pdv_backend.pedido.entity;

import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "pedido")
@Getter @Setter @NoArgsConstructor
public class Pedido extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_pedido")
    private Integer idPedido;

    @Column(name = "referencia", nullable = false, unique = true, length = 50)
    private String referencia;

    @Column(name = "id_usuario", nullable = false)
    private Integer idUsuario;

    @Column(name = "id_tipo_pagamento", nullable = false)
    private Integer idTipoPagamento;

    @Column(name = "status_pedido", nullable = false, length = 50)
    private String statusPedido;

    @Column(name = "total", nullable = false, precision = 12, scale = 2)
    private BigDecimal total;

    @Column(name = "valor_pago", nullable = false, precision = 12, scale = 2)
    private BigDecimal valorPago;

    @Column(name = "troco", insertable = false, updatable = false, precision = 12, scale = 2)
    private BigDecimal troco;

    @Column(name = "ponto_referencia", columnDefinition = "TEXT")
    private String pontoReferencia;

    @Column(name = "observacoes", columnDefinition = "TEXT")
    private String observacoes;

    @Column(name = "data_pedido", nullable = false)
    private LocalDateTime dataPedido;

    @Column(name = "data_finalizacao")
    private LocalDateTime dataFinalizacao;

    @Column(name = "id_cliente")
    private Long idCliente;

    @Column(name = "tipo_venda", nullable = false, length = 20)
private String tipoVenda = "IMEDIATA";

@Column(name = "modalidade_credito", length = 20)
private String modalidadeCredito; // SEM_PARCELAS | PARCELADO

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

// saldo_devedor_credito é GENERATED (calculado pela BD) — mapeado como read-only
@Column(name = "saldo_devedor_credito", insertable = false, updatable = false,
        precision = 12, scale = 2)
private BigDecimal saldoDevedorCredito;

// ── Ajustes de NCR/NDB — colunas de auditoria, aditivas, nunca sobrescrevem `total` ──
@Column(name = "valor_creditado_devolucao", nullable = false, precision = 12, scale = 2)
private BigDecimal valorCreditadoDevolucao = BigDecimal.ZERO;

@Column(name = "valor_debitado_ajuste", nullable = false, precision = 12, scale = 2)
private BigDecimal valorDebitadoAjuste = BigDecimal.ZERO;

/**
 * Saldo devedor real, considerando notas de crédito/débito já aplicadas.
 * Não persistido — derivado em memória a partir de saldoDevedorCredito (BD).
 */
public BigDecimal getSaldoDevedorAjustado() {
    BigDecimal base = saldoDevedorCredito != null
            ? saldoDevedorCredito
            : total.subtract(valorPago != null ? valorPago : BigDecimal.ZERO);

    return base
            .subtract(valorCreditadoDevolucao != null ? valorCreditadoDevolucao : BigDecimal.ZERO)
            .add(valorDebitadoAjuste != null ? valorDebitadoAjuste : BigDecimal.ZERO);
}


    @OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemPedido> itensProduto = new HashSet<>();

    @OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemPedidoServico> itensServico = new HashSet<>();

 @Column(name = "nome_cliente_singular", length = 150)
private String nomeClienteSingular;

@Column(name = "apelido_cliente_singular", length = 150)
private String apelidoClienteSingular;

    // ─── Builder estático mantido — não usa @Builder do Lombok para evitar
    //     conflito com AuditableEntity (mesmo padrão dos outros módulos) ────
    public static Builder builder() { return new Builder(); }

    public static class Builder {
        private final Pedido p = new Pedido();
        public Builder referencia(String v)             { p.referencia = v;        return this; }
        public Builder idUsuario(Integer v)             { p.idUsuario = v;         return this; }
        public Builder idTipoPagamento(Integer v)       { p.idTipoPagamento = v;   return this; }
        public Builder statusPedido(String v)           { p.statusPedido = v;      return this; }
        public Builder total(BigDecimal v)              { p.total = v;             return this; }
        public Builder valorPago(BigDecimal v)          { p.valorPago = v;         return this; }
        public Builder pontoReferencia(String v)        { p.pontoReferencia = v;   return this; }
        public Builder observacoes(String v)            { p.observacoes = v;       return this; }
        public Builder dataPedido(LocalDateTime v)      { p.dataPedido = v;        return this; }
        public Builder dataFinalizacao(LocalDateTime v) { p.dataFinalizacao = v;   return this; }
        public Builder idCliente(Long v)                { p.idCliente = v;         return this; }
        public Builder tipoVenda(String v)                  { p.tipoVenda = v;                    return this; }
public Builder modalidadeCredito(String v)          { p.modalidadeCredito = v;            return this; }
public Builder statusPagamento(String v)            { p.statusPagamento = v;              return this; }
public Builder idDocumentoFacturaCredito(Integer v) { p.idDocumentoFacturaCredito = v;    return this; }
public Builder dataVencimentoCredito(LocalDate v)   { p.dataVencimentoCredito = v;        return this; }
public Builder observacoesCredito(String v)         { p.observacoesCredito = v;           return this; }
public Builder dataAberturaCredito(OffsetDateTime v) { p.dataAberturaCredito = v; return this; }
public Builder dataLiquidacaoCredito(OffsetDateTime v) { p.dataLiquidacaoCredito = v; return this; }
public Builder nomeClienteSingular(String v)    { p.nomeClienteSingular = v;    return this; }
public Builder apelidoClienteSingular(String v) { p.apelidoClienteSingular = v; return this; }

        public Pedido build()                           { return p; }
    }

    public void recalcularTotal() {
        BigDecimal totalProdutos = itensProduto.stream()
                .map(ItemPedido::getSubtotal).filter(s -> s != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalServicos = itensServico.stream()
                .map(ItemPedidoServico::getSubtotal).filter(s -> s != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        this.total = totalProdutos.add(totalServicos);
    }
}