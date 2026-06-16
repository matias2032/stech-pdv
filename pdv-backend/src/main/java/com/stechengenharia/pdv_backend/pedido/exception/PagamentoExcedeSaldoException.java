// PagamentoExcedeSaldoException.java
package com.stechengenharia.pdv_backend.pedido.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

import java.math.BigDecimal;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class PagamentoExcedeSaldoException extends RuntimeException {
    public PagamentoExcedeSaldoException(BigDecimal tentativa, BigDecimal saldo) {
        super(String.format("Valor a pagar (%.2f) excede o saldo devedor (%.2f).",
            tentativa, saldo));
    }
}