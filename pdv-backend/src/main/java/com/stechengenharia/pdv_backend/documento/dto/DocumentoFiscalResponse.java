package com.stechengenharia.pdv_backend.documento.dto;

import com.stechengenharia.pdv_backend.documento.entity.DocumentoFiscal;

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
             String tipoVenda
    ) {
        /** Método de fábrica — converte a entidade para o DTO de resposta. */
        public static DocumentoResponse from(DocumentoFiscal doc) {
            var tipo = doc.getTipoDocumento();
            return new DocumentoResponse(
                    doc.getId(),
                    new TipoDocumentoResponse(
                            tipo.getId(),
                            tipo.getCodigo(),
                            tipo.getNome(),
                            tipo.getPrefixo()
                    ),
                    doc.getIdPedido(),
                    doc.getReferencia(),
                    doc.getNumeroSeq(),
                    doc.getAno(),
                    doc.getCodigoAt(),
                    doc.getUsuario().getId(),
                    doc.getUsuario().getNome() + " " + (doc.getUsuario().getApelido() != null ? doc.getUsuario().getApelido() : ""),
                    doc.getEmitidoEm(),
                    doc.getAnulado(),
                    doc.getMotivoAnulacao(),
                    null                
            );
        }
    }
}