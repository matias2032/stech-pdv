package com.stechengenharia.pdv_backend.marca.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.Instant;

@Entity
@Table(name = "marca")
@Getter @Setter @NoArgsConstructor
public class CloudMarcaEntity {

    @Id
    @Column(name = "id_marca")
    private Integer idMarca;       // SEM @GeneratedValue — ID vem da loja

    @Column(name = "nome_marca", nullable = false, length = 100)
    private String nomeMarca;

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