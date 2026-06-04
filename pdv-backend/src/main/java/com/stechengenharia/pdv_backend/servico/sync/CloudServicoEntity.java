package com.stechengenharia.pdv_backend.servico.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "servico")
@Getter @Setter @NoArgsConstructor
public class CloudServicoEntity {

    @Id
    @Column(name = "id_servico")
    private Integer idServico;          // SEM @GeneratedValue

    @Column(name = "nome_servico", nullable = false, length = 150)
    private String nomeServico;

    @Column(name = "descricao", columnDefinition = "TEXT")
    private String descricao;

    @Column(name = "preco_unitario", nullable = false, precision = 12, scale = 2)
    private BigDecimal precoUnitario;

    @Column(name = "unidade", nullable = false, length = 50)
    private String unidade;

    @Column(name = "ativo", nullable = false)
    private Boolean ativo = true;

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