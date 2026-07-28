package com.stechengenharia.pdv_backend.documento.entity;

import com.stechengenharia.pdv_backend.common.entity.AuditableEntity;
import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "documento_fiscal")
@Getter
 @Setter 
 @NoArgsConstructor 
 @AllArgsConstructor
public class DocumentoFiscal extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_documento")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_tipo_doc", nullable = false)
    private TipoDocumentoFiscal tipoDocumento;

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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;

    @Column(name = "emitido_em", nullable = false, updatable = false)
    private OffsetDateTime emitidoEm;

@Column(nullable = false)
    private Boolean anulado = false;

    @Column(name = "motivo_anulacao")
    private String motivoAnulacao;

    // Fotografia imutável do pedido (itens, preços, total) no momento da
    // emissão. Preenchido apenas para documentos "originais" (FAT/VD).
    // A geração de PDF deve usar este campo, quando presente, em vez de
    // ler o pedido ao vivo — assim a factura nunca muda depois de emitida.
@Column(name = "snapshot_conteudo", columnDefinition = "TEXT")
    private String snapshotConteudo;

    /**
     * Valor total do pedido no momento da emissão (apenas para FAT/VD).
     * Congelado — devoluções/ajustes posteriores no pedido NUNCA alteram
     * este valor. É este campo que extractos/relatórios devem usar como
     * "valor da fatura", nunca pedido.getTotal() ao vivo.
     */
    @Column(name = "valor_total_emissao", precision = 12, scale = 2)
    private BigDecimal valorTotalEmissao;
    
    @PrePersist
    protected void onCreate() {
        if (emitidoEm == null) emitidoEm = OffsetDateTime.now();
        if (anulado == null)   anulado = false;
        // Documento recém-emitido entra como PENDING_CREATE (herdado do AuditableEntity)
    }
}