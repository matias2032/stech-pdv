package com.stechengenharia.pdv_backend.documento.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/** Lançada quando se tenta anular um documento que já foi anulado anteriormente. */
@ResponseStatus(HttpStatus.CONFLICT)
public class DocumentoJaAnuladoException extends RuntimeException {

    public DocumentoJaAnuladoException(String referencia) {
        super("O documento '" + referencia + "' já se encontra anulado.");
    }
}