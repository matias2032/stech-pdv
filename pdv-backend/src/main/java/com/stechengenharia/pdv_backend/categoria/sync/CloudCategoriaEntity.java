package com.stechengenharia.pdv_backend.categoria.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.Instant;

@Entity
@Table(name = "categoria")          // mesma tabela no schema da nuvem
@Getter
@Setter
@NoArgsConstructor
public class CloudCategoriaEntity {

    @Id
    @Column(name = "id_categoria")
    private Integer idCategoria;    // SEM @GeneratedValue — a nuvem recebe o ID da loja

    @Column(name = "nome_categoria", nullable = false, length = 100)
    private String nomeCategoria;

    @Column(name = "descricao", columnDefinition = "TEXT")
    private String descricao;

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