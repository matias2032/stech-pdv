package com.stechengenharia.pdv_backend.pedido.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.CONFLICT)
public class EstoqueInsuficienteException extends RuntimeException {

    public EstoqueInsuficienteException(String nomeProduto, int disponivel, int solicitado) {
        super(String.format(
            "Estoque insuficiente para '%s'. Disponível: %d | Solicitado: %d",
            nomeProduto, disponivel, solicitado
        ));
    }
}