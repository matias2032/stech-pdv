package com.stechengenharia.pdv_backend.pedido.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "documento_fiscal_relacao")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class DocumentoFiscalRelacao {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_relacao")
    private Long idRelacao;

    @Column(name = "id_documento_origem", nullable = false)
    private Integer idDocumentoOrigem;

    @Column(name = "id_documento_relacionado", nullable = false)
    private Integer idDocumentoRelacionado;

    // PAGAMENTO_CREDITO | ANULACAO | REFERENCIA
    @Column(name = "tipo_relacao", nullable = false, length = 30)
    private String tipoRelacao;

    @Column(name = "observacoes", columnDefinition = "TEXT")
    private String observacoes;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @PrePersist
    void onCreate() { if (createdAt == null) createdAt = OffsetDateTime.now(); }
}