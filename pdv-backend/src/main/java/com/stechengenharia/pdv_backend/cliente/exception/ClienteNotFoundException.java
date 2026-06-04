package com.stechengenharia.pdv_backend.cliente.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class ClienteNotFoundException extends RuntimeException {
    public ClienteNotFoundException(Long id) {
        super("Cliente não encontrado com o ID: " + id);
    }
    public ClienteNotFoundException(String message) {
        super(message);
    }
}