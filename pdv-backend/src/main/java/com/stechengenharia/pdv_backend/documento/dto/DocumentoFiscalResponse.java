package com.stechengenharia.pdv_backend.documento.dto;

import com.stechengenharia.pdv_backend.documento.entity.DocumentoFiscal;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public class DocumentoFiscalResponse {

    public record TipoDocumentoResponse(
            Integer id,
            String codigo,
            String nome,
            String prefixo
    ) {}

public record DocumentoResponse(
        Integer id,
        TipoDocumentoResponse tipoDocumento,
        Integer idPedido,
        String referencia,
        Integer numeroSeq,
        Integer ano,
        String codigoAt,
        Long idUsuario,
        String nomeUsuario,
        OffsetDateTime emitidoEm,
        Boolean anulado,
        String motivoAnulacao,
        String tipoVenda,
        String snapshotConteudo,
        BigDecimal valorTotalEmissao
) {
    /** Converte a entidade básica (quando não tem tipoVenda) */
    public static DocumentoResponse from(DocumentoFiscal doc) {
        return from(doc, null);
    }

    /** Converte a entidade recebendo o tipoVenda externamente */
    public static DocumentoResponse from(DocumentoFiscal doc, String tipoVenda) {
        var tipo = doc.getTipoDocumento();
        return new DocumentoResponse(
                doc.getId(),
                new TipoDocumentoResponse(
                        tipo.getId(), tipo.getCodigo(), tipo.getNome(), tipo.getPrefixo()
                ),
                doc.getIdPedido(),
                doc.getReferencia(),
                doc.getNumeroSeq(),
                doc.getAno(),
                doc.getCodigoAt(),
                doc.getUsuario() != null ? doc.getUsuario().getId() : null,
                doc.getUsuario() != null 
                        ? doc.getUsuario().getNome() + " " + (doc.getUsuario().getApelido() != null ? doc.getUsuario().getApelido() : "") 
                        : "",
                doc.getEmitidoEm(),
                doc.getAnulado(),
                doc.getMotivoAnulacao(),
                tipoVenda,
                doc.getSnapshotConteudo(),
                doc.getValorTotalEmissao()
        );
    }
}
    public record NotaRetificativaResponse(
            DocumentoResponse documento,
            Integer idDocumentoOrigem,
            String motivoRetificacao,
            BigDecimal valor
    ) {}
}