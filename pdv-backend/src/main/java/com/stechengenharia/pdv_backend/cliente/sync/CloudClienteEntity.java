package com.stechengenharia.pdv_backend.cliente.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.Instant;

@Entity
@Table(name = "cliente")
@Getter @Setter @NoArgsConstructor
public class CloudClienteEntity {

    @Id
    @Column(name = "id_cliente")
    private Long idCliente;             // SEM @GeneratedValue

    @Column(length = 250)
    private String nome;

    @Column(length = 250)
    private String apelido;

    @Column(unique = true, length = 250)
    private String email;

    @Column(unique = true, length = 250)
    private String nuit;

    @Column(unique = true, length = 250)
    private String contacto;

    @Column(unique = true, length = 250)
    private String morada;

    @Column(name = "id_perfil_cliente", nullable = false)
    private Long idPerfil;              // FK simples — sem JOIN na nuvem

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