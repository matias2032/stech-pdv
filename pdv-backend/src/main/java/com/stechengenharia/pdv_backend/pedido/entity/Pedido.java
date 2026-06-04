package com.stechengenharia.pdv_backend.pedido.entity;

import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;
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

    @OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemPedido> itensProduto = new HashSet<>();

    @OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemPedidoServico> itensServico = new HashSet<>();

    @Transient
    private String nomeClienteSingular;
    @Transient
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