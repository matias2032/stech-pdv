package com.stechengenharia.pdv_backend.despesa.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.OffsetDateTime;

@Entity
@Table(name = "despesa")
@Getter
@Setter
@NoArgsConstructor
public class CloudDespesaEntity {

    @Id
    @Column(name = "id_despesa")
    private Long idDespesa;

    @Column(name = "id_fornecedor")
    private Long idFornecedor;

    @Column(name = "id_tipo_despesa")
private Long idTipoDespesa;

    @Column(name = "descricao", nullable = false, length = 500)
    private String descricao;

    @Column(name = "valor_gasto", nullable = false, precision = 19, scale = 2)
    private BigDecimal valorGasto;

    @Column(name = "data_despesa", nullable = false)
    private OffsetDateTime dataDespesa;

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