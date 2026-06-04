package com.stechengenharia.pdv_backend.pedido.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "pedido_cancelamento")
public class PedidoCancelamento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cancelamento")
    private Integer idCancelamento;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_pedido", nullable = false)
    private Pedido pedido;

    @Column(name = "motivo", columnDefinition = "TEXT")
    private String motivo;

    // FK para usuario — guardado como Integer para manter compatibilidade com o DTO
    @Column(name = "id_usuario_cancelou", nullable = false)
    private Integer idUsuarioCancelou;

    @Column(name = "data_cancelamento", nullable = false)
    private LocalDateTime dataCancelamento;

    // ─── Construtor vazio (obrigatório pelo JPA) ─────────────────────────────
    public PedidoCancelamento() {}

    // ─── Builder estático ─────────────────────────────────────────────────────
    public static Builder builder() { return new Builder(); }

    public static class Builder {
        private final PedidoCancelamento pc = new PedidoCancelamento();
        public Builder pedido(Pedido v)                  { pc.pedido = v;              return this; }
        public Builder motivo(String v)                  { pc.motivo = v;              return this; }
        public Builder idUsuarioCancelou(Integer v)      { pc.idUsuarioCancelou = v;   return this; }
        public Builder dataCancelamento(LocalDateTime v) { pc.dataCancelamento = v;    return this; }
        public PedidoCancelamento build()                { return pc; }
    }

    // ─── Getters ─────────────────────────────────────────────────────────────
    public Integer       getIdCancelamento()    { return idCancelamento; }
    public Pedido        getPedido()            { return pedido; }
    public String        getMotivo()            { return motivo; }
    public Integer       getIdUsuarioCancelou() { return idUsuarioCancelou; }
    public LocalDateTime getDataCancelamento()  { return dataCancelamento; }

    // ─── Setters ─────────────────────────────────────────────────────────────
    public void setIdCancelamento(Integer v)        { this.idCancelamento = v; }
    public void setPedido(Pedido v)                 { this.pedido = v; }
    public void setMotivo(String v)                 { this.motivo = v; }
    public void setIdUsuarioCancelou(Integer v)     { this.idUsuarioCancelou = v; }
    public void setDataCancelamento(LocalDateTime v){ this.dataCancelamento = v; }
}