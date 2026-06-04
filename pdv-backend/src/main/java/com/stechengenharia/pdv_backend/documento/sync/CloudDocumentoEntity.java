package com.stechengenharia.pdv_backend.documento.sync;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.Instant;
import java.time.OffsetDateTime;

@Entity
@Table(name = "documento_fiscal")
@Getter @Setter @NoArgsConstructor
public class CloudDocumentoEntity {

    @Id
    @Column(name = "id_documento")
    private Integer idDocumento;        // SEM @GeneratedValue

    @Column(name = "id_tipo_doc", nullable = false)
    private Integer idTipoDocumento;

    @Column(name = "id_pedido", nullable = false)
    private Integer idPedido;

    @Column(nullable = false, unique = true, length = 30)
    private String referencia;

    @Column(name = "numero_seq", nullable = false)
    private Integer numeroSeq;

    @Column(nullable = false)
    private Integer ano;

    @Column(name = "codigo_at", nullable = false, length = 50)
    private String codigoAt;

    @Column(name = "id_usuario", nullable = false)
    private Long idUsuario;

    @Column(name = "emitido_em", nullable = false)
    private OffsetDateTime emitidoEm;

    @Column(nullable = false)
    private Boolean anulado = false;

    @Column(name = "motivo_anulacao")
    private String motivoAnulacao;

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