// CreditoJaDeclaradoException.java
package com.stechengenharia.pdv_backend.pedido.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;
@ResponseStatus(HttpStatus.CONFLICT)
public class CreditoJaDeclaradoException extends RuntimeException {
    public CreditoJaDeclaradoException(Integer idPedido) {
        super("O pedido " + idPedido + " já foi declarado como venda a crédito.");
    }
}
