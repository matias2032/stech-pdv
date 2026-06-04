package com.stechengenharia.pdv_backend.pedido.entity;

import com.stechengenharia.pdv_backend.servico.entity.Servico;
import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "item_pedido_servico")
public class ItemPedidoServico {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_item_servico")
    private Integer idItemServico;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_pedido", nullable = false)
    private Pedido pedido;

    // Relação com a entidade Servico (se existir) — lazy para evitar N+1
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_servico", nullable = false)
    private Servico servico;

    @Column(name = "quantidade", nullable = false)
    private Integer quantidade;

    @Column(name = "preco_unitario", nullable = false, precision = 12, scale = 2)
    private BigDecimal precoUnitario;

    // subtotal é GENERATED ALWAYS AS (quantidade * preco_unitario) STORED
    // → insertable=false, updatable=false para que o JPA não tente escrever neste campo
@org.hibernate.annotations.Generated
@Column(name = "subtotal", insertable = false, updatable = false)
private BigDecimal subtotal;

    @Column(name = "observacoes", columnDefinition = "TEXT")
    private String observacoes;

    // ─── Construtor vazio (obrigatório pelo JPA) ─────────────────────────────
    public ItemPedidoServico() {}

    // ─── Builder estático ─────────────────────────────────────────────────────
    public static Builder builder() { return new Builder(); }

    public static class Builder {
        private final ItemPedidoServico i = new ItemPedidoServico();
        public Builder pedido(Pedido v)            { i.pedido = v;         return this; }
        public Builder servico(Servico v)          { i.servico = v;        return this; }
        public Builder idServico(Integer v)        { i.servico = new Servico(v); return this; }
        public Builder quantidade(Integer v)       { i.quantidade = v;     return this; }
        public Builder precoUnitario(BigDecimal v) { i.precoUnitario = v;  return this; }
        public Builder observacoes(String v)       { i.observacoes = v;    return this; }
        public ItemPedidoServico build()           { return i; }
    }

    // ─── Getters ─────────────────────────────────────────────────────────────
    public Integer      getIdItemServico()  { return idItemServico; }
    public Pedido       getPedido()         { return pedido; }
    public Servico      getServico()        { return servico; }
    public Integer      getIdServico()      { return servico != null ? servico.getIdServico() : null; }
    public Integer      getQuantidade()     { return quantidade; }
    public BigDecimal   getPrecoUnitario()  { return precoUnitario; }
    public BigDecimal   getSubtotal()       { return subtotal; }
    public String       getObservacoes()    { return observacoes; }

    // ─── Setters ─────────────────────────────────────────────────────────────
    public void setIdItemServico(Integer v)    { this.idItemServico = v; }
    public void setPedido(Pedido v)            { this.pedido = v; }
    public void setServico(Servico v)          { this.servico = v; }
    public void setQuantidade(Integer v)       { this.quantidade = v; }
    public void setPrecoUnitario(BigDecimal v) { this.precoUnitario = v; }
    public void setObservacoes(String v)       { this.observacoes = v; }
}