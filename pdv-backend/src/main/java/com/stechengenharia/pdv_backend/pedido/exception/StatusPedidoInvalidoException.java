package com.stechengenharia.pdv_backend.pedido.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class StatusPedidoInvalidoException extends RuntimeException {

    public StatusPedidoInvalidoException(String statusActual, String operacao) {
        super(String.format(
            "Operação '%s' não permitida para pedido com status '%s'",
            operacao, statusActual
        ));
    }
}