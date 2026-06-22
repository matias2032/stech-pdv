package com.stechengenharia.pdv_backend.despesa.entity;

import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "tipo_despesa")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TipoDespesa extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_tipo_despesa")
    private Long idTipoDespesa;

    @Column(name = "nome_despesa", nullable = false, length = 150)
    private String nomeDespesa;

    @Column(name = "descricao", length = 500)
    private String descricao;

    @PrePersist
    protected void onCreate() {
        if (getSyncStatus() == null) {
            setSyncStatus("PENDING_CREATE");
        }
    }
}