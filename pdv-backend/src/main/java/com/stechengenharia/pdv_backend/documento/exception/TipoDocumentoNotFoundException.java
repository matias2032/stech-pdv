package com.stechengenharia.pdv_backend.documento.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/** Lançada quando o código do tipo de documento fiscal é inválido/inexistente. */
@ResponseStatus(HttpStatus.BAD_REQUEST)
public class TipoDocumentoNotFoundException extends RuntimeException {

    public TipoDocumentoNotFoundException(String codigo) {
        super("Tipo de documento fiscal inválido: " + codigo);
    }

    public TipoDocumentoNotFoundException(Integer id) {
        super("Tipo de documento fiscal não encontrado com id: " + id);
    }
}