package com.stechengenharia.pdv_backend.usuario.entity;
 
import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
 
@Entity
@Table(name = "historico_senhas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class HistoricoSenhas {
 
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_historico")
    private Long id;
 
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;
 
    @Column(name = "senha_hash", nullable = false)
    private String senhaHash;
 
    @Column(name = "data_alteracao", nullable = false)
    private OffsetDateTime dataAlteracao;
 
    @PrePersist
    protected void onCreate() {
        dataAlteracao = OffsetDateTime.now();
    }
}
 