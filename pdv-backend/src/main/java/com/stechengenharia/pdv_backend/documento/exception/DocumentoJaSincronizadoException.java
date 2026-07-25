package com.stechengenharia.pdv_backend.documento.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Lançada quando se tenta anular directamente (via anular()) um documento
 * FAT/VD que já foi sincronizado com a nuvem. Nesse caso o fluxo correcto
 * é emitir uma Nota de Crédito/Débito (emitirNotaRetificativa).
 */
@ResponseStatus(HttpStatus.CONFLICT)
public class DocumentoJaSincronizadoException extends RuntimeException {

    public DocumentoJaSincronizadoException(String referencia) {
        super("O documento '" + referencia + "' já foi sincronizado. Utilize o fluxo de "
                + "Nota de Crédito/Débito (POST /documentos-fiscais/{id}/nota-retificativa) "
                + "em vez de anular directamente.");
    }
}