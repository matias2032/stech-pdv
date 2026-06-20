package com.stechengenharia.pdv_backend.fornecedor.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "fornecedor")
@Getter
@Setter
@NoArgsConstructor
public class CloudFornecedorEntity {

    @Id
    @Column(name = "id_fornecedor")
    private Long idFornecedor; // SEM @GeneratedValue no cloud entity

    @Column(length = 250)
    private String nome;

    @Column(unique = true, length = 250)
    private String email;

    @Column(unique = true, length = 250)
    private String nuit;

    @Column(unique = true, nullable = false, length = 250)
    private String contacto;

    @Column(length = 250)
    private String morada;

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