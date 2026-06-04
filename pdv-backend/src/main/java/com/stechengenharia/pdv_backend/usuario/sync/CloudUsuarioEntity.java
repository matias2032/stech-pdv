package com.stechengenharia.pdv_backend.usuario.sync;
import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "usuario", indexes = {
        @Index(name = "idx_usuario_local_id",  columnList = "local_id"),
        @Index(name = "idx_usuario_updated_at", columnList = "updated_at")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CloudUsuarioEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_usuario")
    private Long id;

    /**
     * ID da loja local que originou este registo.
     * É a chave de idempotência — evita duplicados em re-envios.
     */
    @Column(name = "local_id", nullable = false, unique = true)
    private Long localId;

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

    @Column(nullable = false)
    private Boolean ativo;

    @Column(nullable = false)
    private Boolean deleted;

    /**
     * Versão recebida da loja — usada para resolver conflitos.
     * A nuvem aceita apenas versões maiores que a que já tem.
     */
    @Column(nullable = false)
    private Long version;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt  = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    // ── Factory method ────────────────────────────────────────────────

    public static CloudUsuarioEntity fromSyncDTO(UsuarioSyncDTO dto) {
        return CloudUsuarioEntity.builder()
                .localId(dto.localId())
                .nome(dto.nome())
                .apelido(dto.apelido())
                .telefone(dto.telefone())
                .email(dto.email())
                .senhaHash(dto.senhaHash())
                .ativo(dto.ativo())
                .deleted(dto.deleted())
                .version(dto.version())
                .build();
        // createdAt e updatedAt são preenchidos pelo @PrePersist
    }

    
}
