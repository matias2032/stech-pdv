package com.stechengenharia.pdv_backend.cotacao.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "cotacao")
@Getter
@Setter
@NoArgsConstructor
public class CloudCotacaoEntity {

    @Id
    @Column(name = "id_cotacao")
    private Long idCotacao;             // SEM @GeneratedValue

    @Column(name = "referencia", nullable = false, unique = true, length = 50)
    private String referencia;

    @Column(name = "id_cliente")
    private Long idCliente;

    @Column(name = "id_usuario", nullable = false)
    private Long idUsuario;

    @Column(name = "status_cotacao", nullable = false, length = 20)
    private String statusCotacao;

    @Column(name = "total", nullable = false, precision = 12, scale = 2)
    private BigDecimal total;

    @Column(name = "validade_ate")
    private LocalDate validadeAte;

    @Column(name = "observacoes", columnDefinition = "text")
    private String observacoes;

    @Column(name = "id_pedido_convertido")
    private Integer idPedidoConvertido;

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