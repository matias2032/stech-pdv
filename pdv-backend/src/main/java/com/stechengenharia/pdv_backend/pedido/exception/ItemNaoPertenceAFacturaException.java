package com.stechengenharia.pdv_backend.pedido.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class ItemNaoPertenceAFacturaException extends RuntimeException {
    public ItemNaoPertenceAFacturaException(Integer idPedido, Integer idDocumento) {
        super("O pedido " + idPedido + " não corresponde ao documento " + idDocumento);
    }
}