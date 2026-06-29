package com.stechengenharia.pdv_backend.pedido.entity;

import com.stechengenharia.pdv_backend.produto.entity.Produto;
import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "item_pedido")
public class ItemPedido {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_item_pedido")
    private Integer idItemPedido;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_pedido", nullable = false)
    private Pedido pedido;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_produto", nullable = false)
    private Produto produto;

    @Column(name = "quantidade", nullable = false)
    private Integer quantidade;

    @Column(name = "preco_unitario", nullable = false, precision = 12, scale = 2)
    private BigDecimal precoUnitario;

    @Column(name = "confirmado_credito", nullable = false)
private Boolean confirmadoCredito = false;

    // subtotal é GENERATED ALWAYS AS (quantidade * preco_unitario) STORED
@org.hibernate.annotations.Generated
@Column(name = "subtotal", insertable = false, updatable = false)
private BigDecimal subtotal;

    // ─── Construtor vazio (obrigatório pelo JPA) ─────────────────────────────
    public ItemPedido() {}

    // ─── Builder estático ─────────────────────────────────────────────────────
    public static Builder builder() { return new Builder(); }

    public static class Builder {
        private final ItemPedido i = new ItemPedido();
        public Builder pedido(Pedido v)            { i.pedido = v;        return this; }
        public Builder produto(Produto v)          { i.produto = v;       return this; }
        public Builder quantidade(Integer v)       { i.quantidade = v;    return this; }
        public Builder precoUnitario(BigDecimal v) { i.precoUnitario = v; return this; }
          public Builder confirmadoCredito(Boolean v) {
    i.confirmadoCredito = v;
    return this;
}
        public ItemPedido build()                  { return i; }
      
    }

    // ─── Getters ─────────────────────────────────────────────────────────────
    public Integer    getIdItemPedido()  { return idItemPedido; }
    public Pedido     getPedido()        { return pedido; }
    public Produto    getProduto()       { return produto; }
    public Integer    getQuantidade()    { return quantidade; }
    public BigDecimal getPrecoUnitario() { return precoUnitario; }
    public BigDecimal getSubtotal()      { return subtotal; }
    public Boolean getConfirmadoCredito() {
    return confirmadoCredito;
}

    // ─── Setters ─────────────────────────────────────────────────────────────
    public void setIdItemPedido(Integer v)    { this.idItemPedido = v; }
    public void setPedido(Pedido v)           { this.pedido = v; }
    public void setProduto(Produto v)         { this.produto = v; }
    public void setQuantidade(Integer v)      { this.quantidade = v; }
    public void setPrecoUnitario(BigDecimal v){ this.precoUnitario = v; }
    public void setConfirmadoCredito(Boolean confirmadoCredito) {
    this.confirmadoCredito = confirmadoCredito;
}
}