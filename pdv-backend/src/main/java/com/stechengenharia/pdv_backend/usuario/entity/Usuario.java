package com.stechengenharia.pdv_backend.usuario.entity;

import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "usuario")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Usuario extends AuditableEntity { // ← herda created_at, updated_at, deleted, sync_status, version

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_usuario")
    private Long id;

    @Column(nullable = false, length = 250)
    private String nome;

    @Column(length = 100)
    private String apelido;

    @Column(length = 30)
    private String telefone;

    @Column(nullable = false, unique = true, length = 250)
    private String email;

    @Column(name = "senha_hash", nullable = false)
    private String senhaHash;

    @Builder.Default
    @Column(nullable = false)
    private Boolean ativo = true;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_perfil", nullable = false)
    private Perfil perfil;

    @Builder.Default
    @Column(name = "primeira_senha", nullable = false)
    private Boolean primeiraSenha = true;

    // criadoEm / atualizadoEm foram REMOVIDOS — vivem em AuditableEntity
    // @PrePersist e @PreUpdate foram REMOVIDOS — vivem em AuditableEntity
}
