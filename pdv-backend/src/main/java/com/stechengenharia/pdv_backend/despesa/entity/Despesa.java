package com.stechengenharia.pdv_backend.despesa.entity;

import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;
import com.stechengenharia.pdv_backend.fornecedor.entity.Fornecedor;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "despesa")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Despesa extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_despesa")
    private Long idDespesa;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_fornecedor")
    private Fornecedor fornecedor;

    @ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "id_tipo_despesa")
private TipoDespesa tipoDespesa;

    @Column(name = "descricao", nullable = false, length = 500)
    private String descricao;

    @Column(name = "valor_gasto", nullable = false, precision = 19, scale = 2)
    private BigDecimal valorGasto;

    @Column(name = "data_despesa", nullable = false)
    private OffsetDateTime dataDespesa;

    @Column(name = "motivo_exclusao", length = 500)
     private String motivoExclusao;

    @PrePersist
    protected void onCreate() {
        if (dataDespesa == null) {
            dataDespesa = OffsetDateTime.now();
        }

        if (getSyncStatus() == null) {
            setSyncStatus("PENDING_CREATE");
        }
    }
}