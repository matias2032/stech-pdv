package com.stechengenharia.pdv_backend.documento.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/** Lançada quando um DocumentoFiscal não é encontrado pelo id ou referência. */
@ResponseStatus(HttpStatus.NOT_FOUND)
public class DocumentoFiscalNotFoundException extends RuntimeException {

    public DocumentoFiscalNotFoundException(Integer id) {
        super("Documento fiscal não encontrado com id: " + id);
    }

    public DocumentoFiscalNotFoundException(String referencia) {
        super("Documento fiscal não encontrado com referência: " + referencia);
    }
}