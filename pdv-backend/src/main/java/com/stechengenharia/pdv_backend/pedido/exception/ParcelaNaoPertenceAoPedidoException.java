// ParcelaNaoPertenceAoPedidoException.java

package com.stechengenharia.pdv_backend.pedido.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;
@ResponseStatus(HttpStatus.BAD_REQUEST)
public class ParcelaNaoPertenceAoPedidoException extends RuntimeException {
    public ParcelaNaoPertenceAoPedidoException(Long idParcela, Integer idPedido) {
        super(String.format("Parcela %d não pertence ao pedido %d.", idParcela, idPedido));
    }
}