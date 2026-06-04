package com.stechengenharia.pdv_backend.pedido.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class ItemNaoPertenceAoPedidoException extends RuntimeException {

    public ItemNaoPertenceAoPedidoException(Integer idItem, Integer idPedido) {
        super(String.format(
            "Item %d não pertence ao pedido %d",
            idItem, idPedido
        ));
    }
}