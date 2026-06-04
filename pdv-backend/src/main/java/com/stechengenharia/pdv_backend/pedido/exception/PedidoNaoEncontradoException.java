package com.stechengenharia.pdv_backend.pedido.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

// ─── Pedido não encontrado ────────────────────────────────────────────────

@ResponseStatus(HttpStatus.NOT_FOUND)
public class PedidoNaoEncontradoException extends RuntimeException {
    public PedidoNaoEncontradoException(Integer id) {
        super("Pedido não encontrado: " + id);
    }
}